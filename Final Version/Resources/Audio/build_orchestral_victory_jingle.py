#!/usr/bin/env python3
"""Compose OrchestralVictory_Jingle.wav from correct-placement clips + lastnotejiggle tail.

Sources (same folder):
  - OrchestralCorrect_1.wav … OrchestralCorrect_4.wav
  - lastnotejiggle.wav

Re-run after replacing any source WAV to refresh the orchestral victory jingle.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent
OUTPUT = OUT_DIR / "OrchestralVictory_Jingle.wav"
TARGET_SR = 48000

CORRECT_NOTES = [f"OrchestralCorrect_{i}" for i in range(1, 5)]
TAIL_CLIP = "lastnotejiggle"

# Short arpeggio hits from the real correct-response clips.
NOTE_TRIM_SEC = 0.46
NOTE_GAP_SEC = 0.05
TAIL_OVERLAP_SEC = 0.04
TAIL_TAIL_SEC = 0.12


def read_wav_mono(path: Path) -> list[float]:
    with wave.open(str(path), "rb") as wf:
        channels = wf.getnchannels()
        sample_width = wf.getsampwidth()
        sample_rate = wf.getframerate()
        frame_count = wf.getnframes()
        raw = wf.readframes(frame_count)

    if sample_width == 2:
        count = len(raw) // 2
        samples = struct.unpack(f"<{count}h", raw)
        floats = [s / 32768.0 for s in samples]
    elif sample_width == 3:
        count = len(raw) // 3
        floats = []
        for i in range(count):
            b0, b1, b2 = raw[i * 3], raw[i * 3 + 1], raw[i * 3 + 2]
            value = b0 | (b1 << 8) | (b2 << 16)
            if value & 0x800000:
                value -= 0x1000000
            floats.append(value / 8388608.0)
    else:
        raise ValueError(f"{path.name}: unsupported PCM width {sample_width}")

    if channels == 1:
        mono = floats
    else:
        mono = []
        for i in range(0, len(floats), channels):
            frame = floats[i : i + channels]
            mono.append(sum(frame) / len(frame))

    if sample_rate != TARGET_SR:
        mono = resample_linear(mono, sample_rate, TARGET_SR)

    return mono


def resample_linear(samples: list[float], src_sr: int, dst_sr: int) -> list[float]:
    if src_sr == dst_sr or not samples:
        return samples

    ratio = dst_sr / src_sr
    out_len = max(1, int(round(len(samples) * ratio)))
    out = []
    for i in range(out_len):
        src_pos = i / ratio
        left = int(math.floor(src_pos))
        right = min(left + 1, len(samples) - 1)
        frac = src_pos - left
        out.append(samples[left] * (1.0 - frac) + samples[right] * frac)
    return out


def trim_note(samples: list[float], duration_sec: float) -> list[float]:
    count = min(len(samples), int(TARGET_SR * duration_sec))
    trimmed = samples[:count]
    fade_out = max(1, int(TARGET_SR * 0.08))
    for i in range(fade_out):
        idx = count - fade_out + i
        if 0 <= idx < len(trimmed):
            trimmed[idx] *= 1.0 - (i / fade_out)
    return trimmed


def apply_fade_in(samples: list[float], duration_sec: float) -> list[float]:
    fade = max(1, int(TARGET_SR * duration_sec))
    out = samples[:]
    for i in range(min(fade, len(out))):
        out[i] *= i / fade
    return out


def apply_fade_out(samples: list[float], duration_sec: float) -> list[float]:
    fade = max(1, int(TARGET_SR * duration_sec))
    out = samples[:]
    start = max(0, len(out) - fade)
    for i in range(start, len(out)):
        out[i] *= 1.0 - ((i - start) / fade)
    return out


def place_at(base: list[float], offset_sec: float, clip: list[float], gain: float = 1.0) -> list[float]:
    offset = int(TARGET_SR * offset_sec)
    needed = offset + len(clip)
    if len(base) < needed:
        base = base + [0.0] * (needed - len(base))

    for i, sample in enumerate(clip):
        base[offset + i] += sample * gain
    return base


def normalize(samples: list[float], peak_target: float = 0.96) -> list[float]:
    peak = max(abs(s) for s in samples) or 1.0
    scale = peak_target / peak
    return [max(-1.0, min(1.0, s * scale)) for s in samples]


def write_wav(path: Path, samples: list[float]) -> None:
    pcm = [int(max(-32767, min(32767, round(s * 32767)))) for s in samples]
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(TARGET_SR)
        wf.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


def build_jingle() -> list[float]:
    cursor = 0.0
    mix: list[float] = []

    for note_name in CORRECT_NOTES:
        path = OUT_DIR / f"{note_name}.wav"
        if not path.exists():
            raise FileNotFoundError(f"Missing correct clip: {path.name}")

        clip = trim_note(read_wav_mono(path), NOTE_TRIM_SEC)
        mix = place_at(mix, cursor, clip, gain=0.94)
        cursor += NOTE_TRIM_SEC + NOTE_GAP_SEC

    tail_path = OUT_DIR / f"{TAIL_CLIP}.wav"
    if not tail_path.exists():
        raise FileNotFoundError(f"Missing tail clip: {tail_path.name}")

    tail_samples = read_wav_mono(tail_path)
    tail_start = cursor - TAIL_OVERLAP_SEC
    tail_clip = apply_fade_in(tail_samples, 0.05)
    mix = place_at(mix, tail_start, tail_clip, gain=1.0)

    total_duration = tail_start + len(tail_clip) / TARGET_SR + TAIL_TAIL_SEC
    total_samples = int(TARGET_SR * total_duration)
    if len(mix) < total_samples:
        mix.extend([0.0] * (total_samples - len(mix)))
    else:
        mix = mix[:total_samples]

    mix = apply_fade_out(mix, 0.24)
    return normalize(mix)


def main() -> None:
    jingle = build_jingle()
    write_wav(OUTPUT, jingle)
    duration = len(jingle) / TARGET_SR
    print(f"Wrote {OUTPUT.name}: {duration:.3f}s @ {TARGET_SR} Hz")


if __name__ == "__main__":
    main()

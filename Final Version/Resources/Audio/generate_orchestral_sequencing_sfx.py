#!/usr/bin/env python3
"""Mockup orchestral pizzicato SFX for sequencing (replace WAVs in Resources/Audio)."""

import math
import struct
import wave
from pathlib import Path

SR = 44100
OUT = Path(__file__).resolve().parent

# Step chords: bass + arpeggio (Sol, La, Si, Do maggiore).
STEPS = [
    {"bass": 98.00, "chord": [196.00, 246.94, 293.66]},   # G2  G3 B3 D3
    {"bass": 110.00, "chord": [220.00, 130.81, 164.81]},  # A2  A3 C3 E3
    {"bass": 123.47, "chord": [246.94, 146.83, 185.00]},  # B2  B3 D3 F#3
    {"bass": 65.41, "chord": [130.81, 164.81, 196.00]},   # C2  C3 E3 G3
]


def mix(*tracks):
    length = max(len(t) for t in tracks) if tracks else 0
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max(abs(s) for s in out) or 1.0
    return [max(-1.0, min(1.0, s / peak * 0.92)) for s in out]


def write_wav(path: Path, samples):
    pcm = [int(max(-32767, min(32767, s * 32767))) for s in samples]
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


def pizzicato_pluck(freq, start, duration=0.14, volume=0.55):
    n_total = int(SR * (start + duration + 0.02))
    buf = [0.0] * n_total
    start_i = int(SR * start)
    pluck_n = int(SR * duration)
    for i in range(pluck_n):
        t = i / SR
        env = math.exp(-11.0 * t) * (1.0 - math.exp(-120.0 * t))
        val = 0.0
        for mult, amp in [(1.0, 1.0), (2.0, 0.22), (3.0, 0.08), (4.0, 0.04)]:
            val += amp * math.sin(2 * math.pi * freq * mult * t)
        noise = 0.04 * math.sin(2 * math.pi * 3200 * t) * math.exp(-40 * t)
        idx = start_i + i
        if idx < n_total:
            buf[idx] += (val + noise) * env * volume
    return buf


def place_at(base, start, addition):
    out = list(base)
    start_i = int(SR * start)
    for i, sample in enumerate(addition):
        idx = start_i + i
        if idx < len(out):
            out[idx] += sample
        else:
            out.extend([0.0] * (idx - len(out)))
            out.append(sample)
    return out


def build_pick_loop(step_index):
    step = STEPS[step_index]
    duration = 2.4
    n = int(SR * duration)
    track = [0.0] * n
    bass, chord = step["bass"], step["chord"]
    for cycle_start in (0.0, 1.2):
        pluck = [0.0] * n
        pluck = place_at(pluck, cycle_start, pizzicato_pluck(bass, 0, 0.16, 0.62))
        for i, freq in enumerate(chord):
            pluck = place_at(pluck, cycle_start + 0.28 + i * 0.18, pizzicato_pluck(freq, 0, 0.12, 0.48))
        track = mix(track, pluck)
    # Soft loop crossfade
    fade = int(SR * 0.04)
    for i in range(fade):
        f = i / fade
        track[i] *= f
        track[-(i + 1)] *= f
    return track


def build_correct(step_index):
    step = STEPS[step_index]
    track = [0.0] * int(SR * 0.72)
    track = place_at(track, 0.02, pizzicato_pluck(step["bass"], 0, 0.18, 0.7))
    for i, freq in enumerate(step["chord"]):
        partial = pizzicato_pluck(freq, 0, 0.16, 0.5)
        track = place_at(track, 0.08 + i * 0.05, partial)
    return track


def build_wrong(variant):
    dissonant = [
        [138.59, 146.83, 155.56],
        [146.83, 156.00, 164.81],
        [155.56, 165.00, 174.61],
        [164.81, 174.61, 185.00],
    ][variant]
    track = [0.0] * int(SR * 0.55)
    for i, freq in enumerate(dissonant):
        track = place_at(track, 0.04 + i * 0.07, pizzicato_pluck(freq * (1 + 0.01 * variant), 0, 0.1, 0.42))
    return track


def build_victory_jingle():
    track = [0.0] * int(SR * 3.6)
    t = 0.08
    for step in STEPS:
        bass = pizzicato_pluck(step["bass"], 0, 0.14, 0.58)
        track = place_at(track, t, bass)
        t += 0.12
        for freq in step["chord"]:
            track = place_at(track, t, pizzicato_pluck(freq, 0, 0.11, 0.44))
            t += 0.1
        t += 0.14
    return track


def main():
    for i in range(4):
        write_wav(OUT / f"OrchestralPick_{i + 1}.wav", build_pick_loop(i))
        write_wav(OUT / f"OrchestralCorrect_{i + 1}.wav", build_correct(i))
    for i in range(4):
        write_wav(OUT / f"OrchestralWrong_{i + 1}.wav", build_wrong(i))
    write_wav(OUT / "OrchestralVictory_Jingle.wav", build_victory_jingle())
    print("Orchestral mockup SFX generated in", OUT)


if __name__ == "__main__":
    main()

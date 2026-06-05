#!/usr/bin/env python3
"""Generates felt / upright cinematic piano SFX for the sequencing card game."""

import math
import struct
import wave
from pathlib import Path

SR = 44100
OUT = Path(__file__).resolve().parent

C4, E4, G4, C5 = 261.625565, 329.627557, 391.995436, 523.251131
D4 = 293.664768
A3 = 220.0


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max(abs(s) for s in out) or 1.0
    return [max(-1.0, min(1.0, s / peak)) for s in out]


def to_pcm(samples, volume=0.9):
    return [int(max(-32767, min(32767, s * volume * 32767))) for s in samples]


def env_adsr(t, duration, attack=0.018, decay=0.16, sustain=0.42, release=0.34):
    release_start = max(attack + decay, duration - release)
    if t < attack:
        curve = t / attack
        return curve * curve
    if t < attack + decay:
        progress = (t - attack) / decay
        return 1.0 - (1.0 - sustain) * progress
    if t < release_start:
        return sustain
    progress = (t - release_start) / max(release, 1e-6)
    return sustain * max(0.0, 1.0 - progress)


def felt_upright_piano(freq, duration=0.88, volume=0.52):
    """Warm felt / upright piano: soft attack, woody body, intimate decay."""
    n = int(SR * duration)
    samples = []
    harmonics = [
        (1.0, 1.00, 0.0000),
        (2.0, 0.26, 0.0012),
        (3.0, 0.11, -0.0008),
        (4.0, 0.05, 0.0015),
        (5.0, 0.025, -0.0010),
    ]
    for i in range(n):
        t = i / SR
        value = 0.0
        warmth = 0.72 + 0.28 * math.exp(-2.4 * t / duration)
        for mult, amp, detune in harmonics:
            partial_freq = freq * mult * (1.0 + detune)
            high_roll = math.exp(-0.55 * (mult - 1.0))
            value += amp * high_roll * math.sin(2 * math.pi * partial_freq * t)

        # Woody hammer / body thump at the attack.
        body = 0.10 * math.sin(2 * math.pi * freq * 0.5 * t) * math.exp(-18 * t)
        value += body

        envelope = env_adsr(t, duration, attack=0.020, decay=0.18, sustain=0.38, release=0.36)
        value *= envelope * warmth
        samples.append(value * volume)
    return samples


def felt_piano_low(freq, duration=0.62, volume=0.36):
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        value = (
            1.0 * math.sin(2 * math.pi * freq * t)
            + 0.16 * math.sin(2 * math.pi * freq * 2 * t)
            + 0.06 * math.sin(2 * math.pi * freq * 3 * t)
        )
        value += 0.08 * math.sin(2 * math.pi * freq * 0.5 * t) * math.exp(-14 * t)
        value *= env_adsr(t, duration, attack=0.022, decay=0.20, sustain=0.30, release=0.28)
        samples.append(value * volume)
    return samples


def soft_glockenspiel(freq, duration=0.42, volume=0.16):
    """Gentler bells that sit behind the felt piano."""
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        value = (
            0.55 * math.sin(2 * math.pi * freq * 2 * t)
            + 0.22 * math.sin(2 * math.pi * freq * 3 * t)
        )
        value *= env_adsr(t, duration, attack=0.004, decay=0.10, sustain=0.12, release=0.22)
        samples.append(value * volume)
    return samples


def soft_flute(freq, duration=0.44, volume=0.10):
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        vibrato = 1.0 + 0.003 * math.sin(2 * math.pi * 4.8 * t)
        value = math.sin(2 * math.pi * freq * vibrato * t)
        value += 0.05 * math.sin(2 * math.pi * freq * 2 * vibrato * t)
        value *= env_adsr(t, duration, attack=0.035, decay=0.12, sustain=0.48, release=0.22)
        samples.append(value * volume)
    return samples


def place_at(base, offset, clip):
    out = base[:]
    start = int(offset * SR)
    for i, sample in enumerate(clip):
        idx = start + i
        if idx >= len(out):
            break
        out[idx] += sample
    return out


def write_wav(path, samples):
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", s) for s in to_pcm(samples)))


def card_flip(duration=0.15, volume=0.58):
    """Short papery card flip: noise rustle + soft snap."""
    import random

    random.seed(7)
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        noise = random.random() * 2.0 - 1.0
        attack = 1.0 - math.exp(-200.0 * t)
        decay = math.exp(-26.0 * t)
        flutter = 0.22 * math.sin(2 * math.pi * 2400.0 * t) * math.exp(-38.0 * t)
        snap = 0.12 * math.sin(2 * math.pi * 520.0 * t) * math.exp(-55.0 * t)
        value = (noise * 0.62 + flutter + snap) * attack * decay * volume
        samples.append(value)
    return samples


def toggle_click(duration=0.07, volume=0.52, seed=31, tone_hz=920.0):
    """Short UI toggle click for Flip all."""
    import random

    random.seed(seed)
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        noise = random.random() * 2.0 - 1.0
        click = 0.35 * math.sin(2 * math.pi * tone_hz * t) * math.exp(-90.0 * t)
        env = (1.0 - math.exp(-400.0 * t)) * math.exp(-48.0 * t)
        value = (noise * 0.22 + click) * env * volume
        samples.append(value)
    return samples


def card_pickup(duration=0.09, volume=0.44):
    """Light lift from the deck: quick paper slide."""
    import random

    random.seed(11)
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        noise = random.random() * 2.0 - 1.0
        slide = 0.18 * math.sin(2 * math.pi * (900.0 + 1200.0 * t) * t)
        env = (1.0 - math.exp(-240.0 * t)) * math.exp(-32.0 * t)
        value = (noise * 0.48 + slide) * env * volume
        samples.append(value)
    return samples


def card_place(duration=0.11, volume=0.50):
    """Soft landing in a timeline slot: brief thud + paper settle."""
    import random

    random.seed(19)
    n = int(SR * duration)
    samples = []
    for i in range(n):
        t = i / SR
        noise = random.random() * 2.0 - 1.0
        thud = 0.28 * math.sin(2 * math.pi * 180.0 * t) * math.exp(-42.0 * t)
        tap = 0.14 * math.sin(2 * math.pi * 680.0 * t) * math.exp(-70.0 * t)
        env = (1.0 - math.exp(-320.0 * t)) * math.exp(-24.0 * t)
        value = (noise * 0.40 + thud + tap) * env * volume
        samples.append(value)
    return samples


def build_victory_jingle():
    arp_notes = [C4, E4, G4, C5]
    note_len = 0.16
    gap = 0.040
    cursor = 0.0
    piano = [0.0] * int(SR * 2.8)
    bells = [0.0] * int(SR * 2.8)
    flute = [0.0] * int(SR * 2.8)

    for freq in arp_notes:
        piano = place_at(piano, cursor, felt_upright_piano(freq, duration=note_len + 0.08, volume=0.46))
        bells = place_at(bells, cursor + 0.012, soft_glockenspiel(freq, duration=note_len + 0.14, volume=0.18))
        flute = place_at(flute, cursor + 0.018, soft_flute(freq, duration=note_len + 0.18, volume=0.09))
        cursor += note_len + gap

    chord_start = cursor + 0.03
    chord_duration = 1.15
    chord_freqs = [C4, E4, G4, C5, E4 * 2]
    chord = [0.0] * int(SR * chord_duration)
    for freq in chord_freqs:
        layer = felt_upright_piano(freq, duration=chord_duration, volume=0.18)
        chord = mix(chord, layer)
    piano = place_at(piano, chord_start, chord)
    bells = place_at(bells, chord_start, soft_glockenspiel(C5, duration=chord_duration, volume=0.12))
    bells = place_at(bells, chord_start + 0.05, soft_glockenspiel(E4 * 2, duration=chord_duration * 0.85, volume=0.08))
    flute = place_at(flute, chord_start + 0.04, soft_flute(G4, duration=chord_duration, volume=0.07))

    return mix(piano, bells, flute)


def main():
    write_wav(OUT / "PianoNote_Do.wav", felt_upright_piano(C4, duration=0.92, volume=0.54))
    write_wav(OUT / "PianoNote_Mi.wav", felt_upright_piano(E4, duration=0.90, volume=0.53))
    write_wav(OUT / "PianoNote_Sol.wav", felt_upright_piano(G4, duration=0.86, volume=0.52))
    write_wav(OUT / "PianoNote_DoHigh.wav", felt_upright_piano(C5, duration=0.82, volume=0.50))
    write_wav(OUT / "PianoNote_Re.wav", felt_upright_piano(D4, duration=0.78, volume=0.50))
    write_wav(OUT / "PianoNote_Grave.wav", felt_piano_low(A3))
    write_wav(OUT / "SequencingVictory_Jingle.wav", build_victory_jingle())
    write_wav(OUT / "SequencingFlipAll_1.wav", card_flip())
    write_wav(OUT / "SequencingFlipAll_2.wav", toggle_click(tone_hz=780.0, seed=37))
    print("Felt / upright piano SFX generated in", OUT)


if __name__ == "__main__":
    main()

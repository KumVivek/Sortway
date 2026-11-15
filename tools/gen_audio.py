#!/usr/bin/env python3
"""Synthesises the placeholder SFX and music loop in app/assets/audio.

These are original, generated tones so the game ships with sound before a
bought SFX pack and real music arrive. Replace the .wav files (same names)
to swap them. Usage: python3 tools/gen_audio.py
"""
import math
import os
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "audio")


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples)
        )


def tone(freq, dur, vol=0.6, attack=0.005, decay=None, shape="sine", slide=0.0):
    n = int(RATE * dur)
    decay = dur if decay is None else decay
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (1 + slide * t / dur)
        phase += 2 * math.pi * f / RATE
        s = math.sin(phase)
        if shape == "square":
            s = 0.5 * (1 if s > 0 else -1) + 0.5 * s
        elif shape == "tri":
            s = 2 / math.pi * math.asin(s)
        env = min(1.0, t / attack) * math.exp(-3.5 * t / decay)
        out.append(s * env * vol)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def at(offset, samples):
    return [0.0] * int(RATE * offset) + samples


NOTE = {"C": 261.63, "D": 293.66, "E": 329.63, "F": 349.23, "G": 392.0,
        "A": 440.0, "B": 493.88}


def n(name, octave=4):
    return NOTE[name] * (2 ** (octave - 4))


write("tap", tone(660, 0.07, 0.5, decay=0.05, shape="tri", slide=-0.3))
write("correct", mix(tone(n("E", 5), 0.12, 0.5, decay=0.1),
                     at(0.07, tone(n("A", 5), 0.2, 0.5, decay=0.16))))
write("wrong", mix(tone(196, 0.28, 0.5, decay=0.25, shape="square", slide=-0.35),
                   tone(147, 0.28, 0.35, decay=0.25, shape="tri", slide=-0.3)))
write("coin", mix(tone(n("B", 5), 0.08, 0.45, decay=0.07),
                  at(0.06, tone(n("E", 6), 0.3, 0.45, decay=0.22))))
write("sticker", mix(*[at(0.06 * i, tone(f, 0.25, 0.4, decay=0.2, shape="tri"))
                       for i, f in enumerate([n("C", 5), n("E", 5), n("G", 5), n("C", 6)])]))
write("win", mix(*[at(0.11 * i, tone(f, 0.45, 0.42, decay=0.35))
                   for i, f in enumerate([n("C", 5), n("E", 5), n("G", 5), n("C", 6), n("E", 6)])]))
write("lose", mix(*[at(0.16 * i, tone(f, 0.4, 0.42, decay=0.32, shape="tri"))
                    for i, f in enumerate([n("E", 4), n("D", 4), n("C", 4), n("A", 3)])]))

# Music: a gentle 8-bar loop (C - Am - F - G, twice), 96 bpm.
beat = 60 / 96
chords = [("C", "E", "G"), ("A", "C", "E"), ("F", "A", "C"), ("G", "B", "D")] * 2
bass_oct = {"C": 3, "A": 2, "F": 2, "G": 2}
tracks = []
for bar, (root, third, fifth) in enumerate(chords):
    t0 = bar * 4 * beat
    tracks.append(at(t0, tone(n(root, bass_oct[root]), 4 * beat, 0.3, attack=0.02,
                              decay=3 * beat, shape="tri")))
    arp = [root, fifth, third, fifth, root, fifth, third, fifth]
    for i, name in enumerate(arp):
        octave = 5 if name != root or i else 4
        tracks.append(at(t0 + i * beat / 2,
                         tone(n(name, octave), beat * 0.9, 0.16, attack=0.01,
                              decay=beat * 0.7)))
total = int(RATE * len(chords) * 4 * beat)
music = mix(*tracks)[:total]
music += [0.0] * (total - len(music))
write("music", music)
print("Wrote audio to", os.path.normpath(OUT))

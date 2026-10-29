"""Synthesises the game's soft UI sounds into assets/sounds/.

Run from arrow_escape/: python3 tool/sounds/make_sounds.py
Mono 16-bit 22.05 kHz WAVs keep each file to a few KB.
"""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / "assets" / "sounds"


def tone(freqs, dur, vol=0.35, attack=0.006, glide=1.0):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-5.0 * t / dur)
        f_mul = glide ** (t / dur)
        s = sum(math.sin(2 * math.pi * f * f_mul * t) / (k + 1) for k, f in enumerate(freqs))
        out.append(s * env * vol)
    return out


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


write("swoosh.wav", tone([660, 990], 0.16, glide=1.6))
write("bump.wav", tone([140, 210], 0.18, vol=0.45, glide=0.7))
write("tap.wav", tone([880], 0.05, vol=0.2))
write("win.wav", tone([523.25], 0.12) + tone([659.25], 0.12) + tone([783.99, 1046.5], 0.35))
write("lose.wav", tone([392], 0.16) + tone([311.13], 0.32, glide=0.9))

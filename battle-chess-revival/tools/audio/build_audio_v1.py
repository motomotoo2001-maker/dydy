#!/usr/bin/env python3
"""Deterministically author the Battle Chess Revival v1 audio pack.

Uses only Python stdlib so CI can rebuild the exact WAV assets. The sounds are
short, stylized layers designed for the game's exaggerated Battle Chess tone.
"""
import argparse, math, random, struct, wave
from pathlib import Path

RATE = 22050
TAU = math.tau

def env(t, duration, attack=0.01, release=0.12):
    if t < attack:
        return max(0.0, t / max(attack, 1e-5))
    if t > duration - release:
        return max(0.0, (duration - t) / max(release, 1e-5))
    return 1.0

def write(path, duration, fn, gain=0.86):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = int(duration * RATE)
    data = bytearray()
    for i in range(frames):
        t = i / RATE
        v = max(-1.0, min(1.0, fn(t) * gain))
        data += struct.pack("<h", int(v * 32767))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("AUDIO_ASSET_PASS", path.name, frames)

def tone(freq, t, phase=0.0):
    return math.sin(TAU * freq * t + phase)

def bell(t, freq, decay=3.5):
    return (
        tone(freq, t) * math.exp(-t * decay)
        + 0.46 * tone(freq * 2.01, t) * math.exp(-t * decay * 1.35)
        + 0.24 * tone(freq * 3.98, t) * math.exp(-t * decay * 1.8)
    )

def low_thump(t, freq=72.0, decay=10.0):
    return tone(freq * (1.0 - 0.18 * min(t, 0.12) / 0.12), t) * math.exp(-t * decay)

def noise_fn(seed):
    rng = random.Random(seed)
    table = [rng.uniform(-1.0, 1.0) for _ in range(RATE * 16)]
    return lambda t: table[min(int(t * RATE), len(table) - 1)]

def build(out):
    out = Path(out)
    n1 = noise_fn(11)
    n2 = noise_fn(23)

    # Seam-friendly cathedral drone: integer cycles over 12 seconds.
    duration = 12.0
    freqs = (55.0, 82.5, 110.0, 165.0)
    def ambience(t):
        bed = sum((0.24, 0.13, 0.08, 0.045)[i] * tone(f, t) for i, f in enumerate(freqs))
        air = 0.025 * n1(t) * (0.55 + 0.45 * tone(0.25, t))
        shimmer = 0.025 * tone(440.0, t) * (0.5 + 0.5 * tone(1.0 / duration, t))
        return bed + air + shimmer
    write(out / "cathedral_ambience.wav", duration, ambience, 0.54)

    write(out / "ui_select.wav", 0.16,
          lambda t: env(t, .16, .004, .06) * (0.55 * tone(680, t) + 0.30 * tone(1020, t)), 0.68)

    write(out / "move.wav", 0.24,
          lambda t: env(t, .24, .004, .10) * (
              0.46 * tone(150 + 90 * t / .24, t) + 0.16 * n2(t)
          ), 0.52)

    # Family-weighted ordinary move/landing sounds. These layer the same
    # deterministic synthetic vocabulary with different weight/material reads.
    write(out / "move_pawn.wav", 0.22,
          lambda t: env(t, .22, .002, .08) * (
              0.34 * tone(210 + 120 * t / .22, t) + 0.18 * bell(t, 760, 12) + 0.08 * n1(t) * math.exp(-t * 18)
          ), 0.52)

    write(out / "move_knight.wav", 0.34,
          lambda t: env(t, .34, .002, .13) * (
              0.38 * low_thump(t, 92, 11) + 0.23 * tone(260 + 120 * t, t) + 0.10 * n2(t) * math.exp(-t * 13)
          ), 0.60)

    write(out / "move_bishop.wav", 0.30,
          lambda t: env(t, .30, .004, .12) * (
              0.20 * bell(t, 420, 8) + 0.18 * tone(560 + 300 * t, t) + 0.07 * n1(t) * math.exp(-t * 14)
          ), 0.48)

    write(out / "move_rook.wav", 0.38,
          lambda t: env(t, .38, .001, .16) * (
              0.52 * low_thump(t, 58, 9) + 0.18 * tone(118, t) * math.exp(-t * 8) + 0.12 * n2(t) * math.exp(-t * 11)
          ), 0.70)

    write(out / "move_queen.wav", 0.34,
          lambda t: env(t, .34, .004, .14) * (
              0.16 * low_thump(t, 105, 10) + 0.21 * bell(t, 620, 7) + 0.16 * bell(t, 930, 9)
          ), 0.50)

    write(out / "move_king.wav", 0.42,
          lambda t: env(t, .42, .002, .18) * (
              0.48 * low_thump(t, 62, 8) + 0.16 * bell(t, 180, 6) + 0.10 * n1(t) * math.exp(-t * 10)
          ), 0.68)

    write(out / "check.wav", 0.78,
          lambda t: env(t, .78, .008, .22) * (0.62 * bell(t, 392, 4.5) + 0.25 * bell(t, 587.3, 5.0)), 0.66)

    write(out / "checkmate.wav", 1.35,
          lambda t: env(t, 1.35, .006, .35) * (
              0.42 * bell(t, 196, 2.6) + 0.34 * bell(t, 293.66, 2.8) + 0.30 * bell(t, 392, 3.0)
              + 0.22 * low_thump(t, 55, 4.3)
          ), 0.76)

    # Signature impacts — intentionally different spectral identities.
    write(out / "impact_pawn.wav", 0.36,
          lambda t: env(t, .36, .002, .12) * (
              0.48 * low_thump(t, 96, 13) + 0.25 * bell(t, 820, 10) + 0.14 * n1(t) * math.exp(-t * 18)
          ), 0.82)

    write(out / "impact_knight.wav", 0.52,
          lambda t: env(t, .52, .002, .18) * (
              0.70 * low_thump(t, 64, 9.0) + 0.19 * n2(t) * math.exp(-t * 14)
              + 0.12 * bell(t, 310, 8)
          ), 0.88)

    write(out / "impact_bishop.wav", 0.58,
          lambda t: env(t, .58, .004, .18) * (
              0.35 * low_thump(t, 78, 8.5)
              + 0.24 * tone(460 + 800 * t, t) * math.exp(-t * 5.5)
              + 0.15 * n1(t) * math.exp(-t * 10)
          ), 0.78)

    write(out / "impact_rook.wav", 0.72,
          lambda t: env(t, .72, .001, .24) * (
              0.82 * low_thump(t, 48, 7.2)
              + 0.23 * tone(96, t) * math.exp(-t * 8)
              + 0.20 * n2(t) * math.exp(-t * 11)
          ), 0.92)

    write(out / "impact_queen.wav", 0.78,
          lambda t: env(t, .78, .006, .24) * (
              0.27 * low_thump(t, 84, 7.0)
              + 0.30 * bell(t, 523.25, 4.6)
              + 0.25 * bell(t, 783.99, 5.2)
              + 0.09 * tone(1300 + 900 * t, t) * math.exp(-t * 4)
          ), 0.74)

    write(out / "impact_king.wav", 0.86,
          lambda t: env(t, .86, .002, .28) * (
              0.74 * low_thump(t, 52, 6.5)
              + 0.25 * bell(t, 146.83, 4.5)
              + 0.16 * n1(t) * math.exp(-t * 9.5)
          ), 0.88)

    print("AUDIO_PACK_BUILD_PASS", out)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--output", required=True)
    a = p.parse_args()
    build(a.output)

if __name__ == "__main__":
    main()

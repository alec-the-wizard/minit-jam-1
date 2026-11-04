"""Generate the looping background music for Card Rush.

The track is synthesised from scratch with the standard library, so
``assets/music/theme.wav`` can be rebuilt at any time:

    python tools/make_music.py

Notes are mixed into a circular buffer, which keeps the loop seamless: the
tails of the last bar wrap around into the first one. The result is a soft
lounge loop in A minor that fits the card table.
"""

from __future__ import annotations

import array
import math
import random
import wave
from pathlib import Path

RATE = 44100
BPM = 88
BEATS_PER_BAR = 4
BARS = 8
TAU = math.tau

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "assets" / "music" / "theme.wav"

# root midi note + chord tones for one bar each, repeated over the loop.
CHORDS: list[tuple[int, list[int]]] = [
    (45, [57, 60, 64, 67, 71]),  # Am9
    (38, [50, 53, 57, 60, 64]),  # Dm9
    (43, [55, 59, 62, 65, 69]),  # G13
    (48, [60, 64, 67, 71, 74]),  # Cmaj9
]

# Which chord tone each eighth note of the arpeggio plays.
ARP_EVEN = [0, 2, 1, 3, 2, 4, 3, 1]
ARP_ODD = [0, 1, 2, 3, 4, 3, 2, 1]

BEAT = 60.0 / BPM
LOOP_SECONDS = BARS * BEATS_PER_BAR * BEAT
FRAMES = round(LOOP_SECONDS * RATE)


def midi_to_hz(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def envelope(t: float, duration: float, attack: float, release: float, decay: float) -> float:
    attack_gain = min(1.0, t / attack) if attack > 0.0 else 1.0
    release_left = duration - t
    release_gain = min(1.0, release_left / release) if release > 0.0 else 1.0
    return max(0.0, attack_gain) * max(0.0, release_gain) * math.exp(-decay * t)


def add_note(
    buf: array.array[float],
    start: float,
    note: int,
    duration: float,
    gain: float,
    partials: list[tuple[float, float]],
    decay: float,
    attack: float = 0.004,
    release: float = 0.06,
) -> None:
    freq = midi_to_hz(note)
    count = int(duration * RATE)
    first = int(round(start * RATE)) % len(buf)
    for i in range(count):
        t = i / RATE
        amp = envelope(t, duration, attack, release, decay)
        sample = 0.0
        for ratio, level in partials:
            sample += level * math.sin(TAU * freq * ratio * t)
        buf[(first + i) % len(buf)] += sample * amp * gain


def add_kick(buf: array.array[float], start: float, gain: float) -> None:
    count = int(0.18 * RATE)
    first = int(round(start * RATE)) % len(buf)
    phase = 0.0
    for i in range(count):
        t = i / RATE
        freq = 42.0 + 95.0 * math.exp(-t * 32.0)
        phase += TAU * freq / RATE
        amp = (1.0 - math.exp(-t * 900.0)) * math.exp(-t * 20.0)
        buf[(first + i) % len(buf)] += math.sin(phase) * amp * gain


def add_shaker(buf: array.array[float], start: float, gain: float, rng: random.Random) -> None:
    count = int(0.09 * RATE)
    first = int(round(start * RATE)) % len(buf)
    previous = 0.0
    for i in range(count):
        t = i / RATE
        noise = rng.uniform(-1.0, 1.0)
        high = noise - previous * 0.92
        previous = noise
        amp = (1.0 - math.exp(-t * 420.0)) * math.exp(-t * 55.0)
        buf[(first + i) % len(buf)] += high * amp * gain


def compose() -> array.array[float]:
    buf = array.array("d", [0.0]) * FRAMES
    rng = random.Random(20261104)

    pluck = [(1.0, 1.0), (2.0, 0.32), (3.0, 0.12), (4.0, 0.05)]
    pad_voice = [(1.0, 1.0), (1.003, 0.45), (2.0, 0.16), (3.0, 0.05)]
    bass_voice = [(1.0, 1.0), (2.0, 0.28), (3.0, 0.08)]
    comp_voice = [(1.0, 1.0), (2.0, 0.22), (3.0, 0.08)]

    for bar in range(BARS):
        root, tones = CHORDS[bar % len(CHORDS)]
        bar_start = bar * BEATS_PER_BAR * BEAT

        # Warm pad, one chord per bar.
        for index, note in enumerate(tones):
            add_note(
                buf,
                bar_start,
                note,
                BEATS_PER_BAR * BEAT * 0.94,
                0.030 if index < 4 else 0.022,
                pad_voice,
                decay=0.16,
                attack=0.22,
                release=0.55,
            )

        # Bass: root on 1, root on 3, fifth as a pickup into the next bar.
        for beat, interval, length, level in (
            (0.0, 0, 1.7 * BEAT, 0.20),
            (2.0, 0, 1.1 * BEAT, 0.16),
            (3.5, 7, 0.45 * BEAT, 0.11),
        ):
            add_note(
                buf,
                bar_start + beat * BEAT,
                root + interval,
                length,
                level,
                bass_voice,
                decay=1.5,
                attack=0.008,
                release=0.10,
            )

        # Electric-piano comping on the offbeats.
        for beat in (1.5, 3.5):
            for note in (tones[1], tones[3], tones[4]):
                add_note(
                    buf,
                    bar_start + beat * BEAT,
                    note,
                    0.5 * BEAT,
                    0.030,
                    comp_voice,
                    decay=4.0,
                    attack=0.006,
                    release=0.05,
                )

        # Arpeggio over the chord, lightly swung.
        pattern = ARP_EVEN if bar % 2 == 0 else ARP_ODD
        for step, tone_index in enumerate(pattern):
            swing = 0.07 * BEAT if step % 2 else 0.0
            note = tones[tone_index] + (12 if step in (4, 7) and bar % 2 == 1 else 0)
            add_note(
                buf,
                bar_start + (step * 0.5) * BEAT + swing,
                note,
                0.62 * BEAT,
                0.052,
                pluck,
                decay=3.4,
                attack=0.004,
                release=0.08,
            )

        # Soft rhythm section.
        add_kick(buf, bar_start, 0.26)
        add_kick(buf, bar_start + 2.0 * BEAT, 0.20)
        for step in range(8):
            swing = 0.07 * BEAT if step % 2 else 0.0
            level = 0.028 if step % 2 else 0.016
            add_shaker(buf, bar_start + (step * 0.5) * BEAT + swing, level, rng)

    return buf


def write_wav(buf: array.array[float]) -> None:
    peak = max(abs(sample) for sample in buf)
    scale = 0.82 / peak if peak > 0.0 else 0.0

    pcm = array.array("h", (int(max(-1.0, min(1.0, sample * scale)) * 32767) for sample in buf))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(pcm.tobytes())


def main() -> None:
    buf = compose()
    write_wav(buf)
    print(f"wrote {OUTPUT} ({LOOP_SECONDS:.2f} s, {FRAMES} frames)")


if __name__ == "__main__":
    main()

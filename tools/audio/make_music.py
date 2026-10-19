"""Gera a trilha e o ambiente provisórios da Fase 5 (síntese própria, sem material de terceiros).

Uso:
    python tools/audio/make_music.py            # grava em game/assets/audio/music/
    python tools/audio/make_music.py --check    # confere se os .wav versionados batem

GDD: "trilha de violão e flauta relaxante; ruídos de natureza por região (sapos,
vento, água batendo no casco)". Dois loops, em WAV mono 16 bits, 22.050 Hz:

- lake_theme: violão dedilhado (síntese Karplus-Strong de corda pinçada) em Sol
  maior, G–Em–C–D a 84 bpm, com uma flauta (senoide com harmônico, vibrato e
  sopro) entrando na segunda metade. A cauda das notas no fim é somada ao começo,
  então o loop emenda sem corte.
- margem_rasa_ambience: vento, água batendo no casco, pássaros e sapos.

Sem aleatoriedade solta: todo ruído usa semente fixa, então a mesma entrada gera
sempre os mesmos bytes (o CI confere).
"""

from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_placeholder_sfx as sfx  # noqa: E402

OUT_DIR = sfx.REPO_ROOT / "game" / "assets" / "audio" / "music"
RATE = sfx.RATE
BPM = 84.0
BEAT_S = 60.0 / BPM
BAR_S = BEAT_S * 4

# Notas (Hz). Acordes de violão em Sol maior: (baixo, quinta, oitava, terça).
NOTE = {
    "D3": 146.83, "E3": 164.81, "G3": 196.00, "A3": 220.00, "B3": 246.94, "C4": 261.63,
    "D4": 293.66, "E4": 329.63, "F#4": 369.99, "G4": 392.00, "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "G2": 98.00, "E2": 82.41, "C3": 130.81, "D2": 73.42,
}
CHORDS = {
    "G": ("G2", "D3", "G3", "B3"),
    "Em": ("E2", "B3", "E3", "G3"),
    "C": ("C3", "G3", "C4", "E4"),
    "D": ("D2", "A3", "D3", "F#4"),
}
PROGRESSION = ["G", "Em", "C", "D"] * 4
# Dedilhado por compasso (colcheias): índices em (baixo, quinta, oitava, terça).
PICKING = [0, 1, 2, 3, 1, 2, 3, 1]
# Melodia da flauta (nota, duração em tempos), a partir do 9º compasso, pentatônica de Sol.
MELODY = [
    ("D5", 1.5), ("B4", 0.5), ("A4", 1.0), ("G4", 1.0),
    ("E4", 2.0), ("G4", 1.0), ("A4", 1.0),
    ("B4", 1.5), ("D5", 0.5), ("E5", 1.0), ("D5", 1.0),
    ("A4", 3.0), (None, 1.0),
    ("D5", 1.5), ("E5", 0.5), ("D5", 1.0), ("B4", 1.0),
    ("A4", 2.0), ("G4", 1.0), ("E4", 1.0),
    ("D4", 1.5), ("E4", 0.5), ("G4", 1.0), ("A4", 1.0),
    ("G4", 3.0), (None, 1.0),
]


def pluck(freq: float, seconds: float, seed: int, brightness: float = 0.5, decay: float = 0.996) -> list[float]:
    """Corda pinçada (Karplus-Strong): ruído numa linha de atraso com filtro de média."""
    rng = random.Random(seed)
    period = max(2, int(round(RATE / freq)))
    line = [rng.uniform(-1.0, 1.0) for _ in range(period)]
    # Ataque mais macio: suaviza o ruído inicial (dedo, não palheta).
    for k in range(1, period):
        line[k] = brightness * line[k] + (1.0 - brightness) * line[k - 1]
    out = []
    idx = 0
    ramp = int(RATE * 0.002)
    for k in range(int(RATE * seconds)):
        nxt = (idx + 1) % period
        value = line[idx]
        line[idx] = decay * 0.5 * (line[idx] + line[nxt])
        # Rampa de 2 ms no ataque: sem ela, o ruído inicial em amplitude cheia estala.
        out.append(value * min(1.0, k / ramp))
        idx = nxt
    return out


def flute(freq: float, seconds: float, seed: int) -> list[float]:
    """Flauta: senoide com 2º harmônico, vibrato que entra depois do ataque e sopro."""
    rng = random.Random(seed)
    n = int(RATE * seconds)
    phase = 0.0
    breath = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        vibrato = 1.0 + 0.006 * math.sin(2 * math.pi * 5.2 * t) * min(1.0, max(0.0, (t - 0.18) / 0.25))
        phase += 2 * math.pi * freq * vibrato / RATE
        breath = 0.85 * breath + 0.15 * rng.uniform(-1.0, 1.0)
        attack = min(1.0, t / 0.08)
        release = min(1.0, max(0.0, (seconds - t) / 0.15))
        out.append((math.sin(phase) + 0.18 * math.sin(2 * phase) + 0.06 * breath) * attack * release)
    return out


def add_at(track: list[float], samples: list[float], start_s: float, gain: float) -> None:
    start = int(start_s * RATE)
    for k, value in enumerate(samples):
        j = start + k
        if j >= len(track):
            break
        track[j] += value * gain


def wrap_tail(track: list[float], loop_samples: int) -> list[float]:
    """Soma o que passou do fim do loop ao começo (o loop emenda sem corte)."""
    out = track[:loop_samples]
    for k in range(loop_samples, len(track)):
        out[k - loop_samples] += track[k]
    return out


def lake_theme() -> list[float]:
    bars = len(PROGRESSION)
    loop_s = bars * BAR_S
    tail_s = 2.0
    track = [0.0] * int(RATE * (loop_s + tail_s))
    note_index = 0
    for bar, chord_name in enumerate(PROGRESSION):
        chord = CHORDS[chord_name]
        for step, pick in enumerate(PICKING):
            start = bar * BAR_S + step * BEAT_S / 2
            # Levíssimo "swing" humano: notas fora do tempo forte atrasam um pouco.
            start += 0.012 if step % 2 else 0.0
            gain = 0.55 if step == 0 else 0.38
            add_at(track, pluck(NOTE[chord[pick]], 1.6, seed=note_index, brightness=0.45 if step else 0.6),
                   start, gain)
            note_index += 1
    t = 8 * BAR_S
    for k, (name, beats) in enumerate(MELODY):
        seconds = beats * BEAT_S
        if name is not None:
            add_at(track, flute(NOTE[name], seconds * 0.98, seed=1000 + k), t, 0.32)
        t += seconds
    return wrap_tail(track, int(RATE * loop_s))


def margem_rasa_ambience() -> list[float]:
    """Vento, água batendo no casco, pássaros e sapos (loop de 24 s)."""
    loop_s = 24.0
    n = int(RATE * loop_s)
    track = [0.0] * (n + int(RATE * 2.0))
    rng = random.Random(77)
    # Vento: ruído bem grave com o volume subindo e descendo devagar.
    wind = sfx.noise(loop_s + 2.0, seed=71, smooth=0.995, attack=0.0, release=0.0, volume=0.5)
    for i, value in enumerate(wind):
        swell = 0.55 + 0.45 * math.sin(2 * math.pi * i / RATE / 8.0)
        track[i] += value * swell * 0.5
    # Água batendo no casco: estalos graves a cada ~1,7 s.
    t = 0.3
    k = 0
    while t < loop_s:
        lap = sfx.noise(0.35, seed=200 + k, smooth=0.97, attack=0.05, release=0.7, volume=0.6)
        add_at(track, lap, t, 0.5)
        t += 1.5 + rng.uniform(0.0, 0.5)
        k += 1
    # Pássaros: trinados (varreduras agudas) em grupos.
    t = 1.0
    while t < loop_s - 1.0:
        for note in range(rng.randint(2, 4)):
            f0 = rng.uniform(2600.0, 3600.0)
            chirp = sfx.tone(f0, f0 * rng.uniform(1.15, 1.4), 0.09, attack=0.1, release=0.5, volume=0.5)
            add_at(track, chirp, t + note * 0.13, 0.22)
        t += rng.uniform(2.5, 5.0)
    # Sapos: coaxar (tom grave pulsado) de vez em quando.
    t = 3.0
    while t < loop_s - 1.0:
        n_croak = int(RATE * 0.25)
        f = rng.uniform(380.0, 520.0)
        croak = [math.sin(2 * math.pi * f * i / RATE) * (0.5 + 0.5 * math.sin(2 * math.pi * 32.0 * i / RATE))
                 * sfx.envelope(i, n_croak, 0.1, 0.4) for i in range(n_croak)]
        add_at(track, croak, t, 0.2)
        add_at(track, croak, t + 0.35, 0.16)
        t += rng.uniform(4.0, 7.0)
    return wrap_tail(track, n)


TRACKS = {"lake_theme": lake_theme, "margem_rasa_ambience": margem_rasa_ambience}


def build_all() -> dict[str, bytes]:
    return {name: sfx.render(make()) for name, make in TRACKS.items()}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="só confere os arquivos versionados")
    args = parser.parse_args(argv)
    built = build_all()
    problems = []
    for name, data in built.items():
        path = OUT_DIR / f"{name}.wav"
        if args.check:
            if not path.is_file() or path.read_bytes() != data:
                problems.append(f"{path.name} difere do gerador (rode sem --check e versione)")
        else:
            OUT_DIR.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            print(f"gravado {path.relative_to(sfx.REPO_ROOT)} ({len(data) / 1024:.0f} KiB)")
    if problems:
        print("FALHOU — trilha provisória:\n  - " + "\n  - ".join(problems))
        return 1
    print(f"OK — {len(built)} faixa(s) da trilha provisória.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

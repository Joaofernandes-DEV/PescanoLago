"""Gera os efeitos sonoros provisórios do protótipo (síntese própria, sem material de terceiros).

Uso:
    python tools/audio/make_placeholder_sfx.py            # grava em game/assets/audio/sfx/
    python tools/audio/make_placeholder_sfx.py --check    # confere se os .wav versionados batem

Cada som é sintetizado com senoides, ruído com semente fixa e envelopes simples,
em WAV mono 16 bits, 22.050 Hz. A mesma entrada gera sempre os mesmos bytes.
Começaram como placeholders da Fase 3; a Fase 5 acrescentou a pancada do casco
(hull_bump). A trilha e o ambiente da Fase 5 ficam em make_music.py.
"""

from __future__ import annotations

import argparse
import io
import math
import random
import struct
import sys
import wave
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "game" / "assets" / "audio" / "sfx"
RATE = 22050


def envelope(i: int, n: int, attack: float, release: float) -> float:
    t = i / n
    if t < attack:
        return t / attack
    if t > 1.0 - release:
        return max(0.0, (1.0 - t) / release)
    return 1.0


def tone(freq_start: float, freq_end: float, seconds: float, attack: float = 0.02,
         release: float = 0.3, volume: float = 0.6) -> list[float]:
    n = int(RATE * seconds)
    phase = 0.0
    out = []
    for i in range(n):
        freq = freq_start + (freq_end - freq_start) * i / n
        phase += 2 * math.pi * freq / RATE
        out.append(volume * math.sin(phase) * envelope(i, n, attack, release))
    return out


def noise(seconds: float, seed: int, smooth: float, attack: float = 0.01, release: float = 0.5,
          volume: float = 0.5) -> list[float]:
    """Ruído filtrado (passa-baixa de 1 polo): smooth perto de 1 = mais grave."""
    rng = random.Random(seed)
    n = int(RATE * seconds)
    value = 0.0
    out = []
    for i in range(n):
        value = smooth * value + (1.0 - smooth) * rng.uniform(-1.0, 1.0)
        out.append(volume * value * envelope(i, n, attack, release) / max(1.0 - smooth, 0.05) ** 0.5)
    return out


def mix(*tracks: list[float]) -> list[float]:
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def concat(*tracks: list[float]) -> list[float]:
    return [s for t in tracks for s in t]


def silence(seconds: float) -> list[float]:
    return [0.0] * int(RATE * seconds)


def loopable(samples: list[float], fade: float = 0.05) -> list[float]:
    """Cruza o fim com o começo para o loop não estalar."""
    n = int(RATE * fade)
    head, body = samples[:n], samples[n:]
    for i in range(n):
        body[-n + i] = body[-n + i] * (1 - i / n) + head[i] * (i / n)
    return body


SOUNDS = {
    # Lançamento: a vara corta o ar e a linha sai da carretilha.
    "cast_whoosh": lambda: mix(noise(0.38, 11, 0.7, 0.04, 0.7, 0.6), tone(900, 280, 0.32, 0.03, 0.75, 0.12)),
    # Isca caindo na água.
    "splash": lambda: mix(noise(0.45, 1, 0.55, 0.005, 0.8, 0.7), tone(420, 180, 0.25, 0.01, 0.7, 0.25)),
    # Boia afundando: o peixe mordeu.
    "bite_plop": lambda: mix(tone(620, 260, 0.18, 0.005, 0.6, 0.6), noise(0.12, 2, 0.4, 0.005, 0.8, 0.2)),
    # Latido curto do Bolota (cardume ou peixe raro por perto).
    "bark": lambda: concat(mix(tone(520, 380, 0.12, 0.01, 0.4, 0.5), noise(0.12, 3, 0.3, 0.01, 0.4, 0.35)),
                           silence(0.08),
                           mix(tone(560, 400, 0.1, 0.01, 0.4, 0.45), noise(0.1, 4, 0.3, 0.01, 0.4, 0.3))),
    # Fisgada: puxão rápido da vara.
    "hook_set": lambda: mix(noise(0.25, 5, 0.2, 0.002, 0.9, 0.35), tone(300, 900, 0.18, 0.002, 0.8, 0.3)),
    # Clique da carretilha (tocado em sequência enquanto recolhe).
    "reel_tick": lambda: mix(noise(0.03, 6, 0.1, 0.001, 0.9, 0.5), tone(2400, 2000, 0.03, 0.001, 0.9, 0.2)),
    # Linha arrebentando.
    "line_snap": lambda: concat(mix(noise(0.08, 7, 0.05, 0.001, 0.6, 0.8), tone(1800, 600, 0.08, 0.001, 0.6, 0.4)),
                                tone(220, 110, 0.3, 0.01, 0.9, 0.2)),
    # Peixe pego: arpejo alegre (dó-mi-sol-dó).
    "catch_jingle": lambda: concat(*(tone(f, f, 0.11, 0.01, 0.5, 0.45) for f in (523.25, 659.25, 783.99, 1046.5))),
    # Fim do dia: sino.
    "day_end_chime": lambda: mix(tone(880, 880, 1.2, 0.005, 0.95, 0.35), tone(1320, 1320, 1.0, 0.005, 0.95, 0.2),
                                 tone(440, 440, 1.4, 0.005, 0.95, 0.25)),
    # Pancada do casco do barco num obstáculo (cais, margem, barco ancorado).
    "hull_bump": lambda: mix(tone(110, 55, 0.3, 0.003, 0.85, 0.6), noise(0.25, 10, 0.92, 0.003, 0.8, 0.5)),
    # Clique de interface.
    "ui_click": lambda: tone(1200, 900, 0.05, 0.002, 0.8, 0.35),
    # Motor de popa fraco (loop).
    "engine_loop": lambda: loopable(mix(*(tone(f, f, 2.0, 0.0, 0.0, v) for f, v in ((55, 0.35), (110, 0.2), (165, 0.1))),
                                        noise(2.0, 8, 0.9, 0.0, 0.0, 0.15))),
    # Água batendo no casco (ambiente, loop).
    "water_ambience": lambda: loopable(noise(4.0, 9, 0.97, 0.0, 0.0, 0.35)),
}


def render(samples: list[float]) -> bytes:
    # Normaliza todos os sons para o mesmo pico (volume parecido entre eles).
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.9 / peak
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples)
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(frames)
    return buffer.getvalue()


def build_all() -> dict[str, bytes]:
    return {name: render(make()) for name, make in SOUNDS.items()}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="compara com os .wav versionados")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    sounds = build_all()
    if args.check:
        errors = [name for name, data in sounds.items()
                  if not (OUT_DIR / f"{name}.wav").is_file() or (OUT_DIR / f"{name}.wav").read_bytes() != data]
        if errors:
            print("FALHOU — sons diferentes do gerador: " + ", ".join(errors))
            return 1
        print(f"OK — {len(sounds)} sons idênticos ao gerador.")
        return 0
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, data in sounds.items():
        (OUT_DIR / f"{name}.wav").write_bytes(data)
        print(f"{name}.wav  {len(data) / RATE / 2:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())

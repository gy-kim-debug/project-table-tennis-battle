"""Create original short arcade cues as mono 16-bit PCM WAVs; no runtime dependency."""
from pathlib import Path
import math, random, struct, wave

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/audio'
RATE = 22050
random.seed(20261013)

# name: duration, start/end pitch, noise mix, decay, extra harmonic
CUES = {
    'swing':   (.115, 350, 150, .16, .35),
    'good':    (.120, 440, 620, .08, .40),
    'perfect': (.270, 660, 1320, .09, .62),
    'miss':    (.220, 250, 95, .28, .18),
    'bounce':  (.065, 225, 150, .14, .12),
    'damage':  (.170, 150, 70, .50, .48),
    'smash':   (.210, 280, 830, .31, .65),
    'victory': (.420, 523, 1046, .03, .60),
    'defeat':  (.430, 311, 120, .12, .30),
}

def create(name, duration, first, last, noise, decay):
    count = round(duration * RATE)
    values = []
    phase = 0.0
    for index in range(count):
        u = index / max(1, count - 1)
        frequency = first * (last / first) ** u
        if name == 'victory':
            frequency *= (1.0, 1.25, 1.5)[min(2, int(u * 3))]
        phase += math.tau * frequency / RATE
        envelope = min(1.0, u * 42.0) * (1.0 - u) ** (1.0 + decay * 5.0)
        square = math.tanh(2.7 * math.sin(phase))
        harmonic = math.sin(phase * 2.0) * 0.18
        grit = (random.random() * 2.0 - 1.0) * noise
        sample = max(-1.0, min(1.0, (square + harmonic + grit) * envelope * 0.52))
        values.append(round(sample * 32767))
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(struct.pack('<' + 'h' * count, *values))
    print(name, duration)

for cue, parameters in CUES.items():
    create(cue, *parameters)

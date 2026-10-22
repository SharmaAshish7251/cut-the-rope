import math
import struct
import wave
import os
import random

SAMPLE_RATE = 44100

def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as wav:
        wav.setnchannels(1)  # mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for s in samples:
            # clamp
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32760)
            packed.extend(struct.pack('<h', val))
        wav.writeframes(packed)
    print(f"Generated {path} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def make_envelope(attack, decay, sustain_level, release, total_len):
    """ADSR envelope generator"""
    env = []
    a_len = int(attack * SAMPLE_RATE)
    d_len = int(decay * SAMPLE_RATE)
    r_len = int(release * SAMPLE_RATE)
    s_len = max(0, total_len - a_len - d_len - r_len)

    for i in range(a_len):
        env.append(i / a_len)
    for i in range(d_len):
        progress = i / d_len
        env.append(1.0 - progress * (1.0 - sustain_level))
    for _ in range(s_len):
        env.append(s_level := sustain_level)
    for i in range(r_len):
        progress = i / r_len
        env.append(sustain_level * (1.0 - progress))
    # Pad or trim to exact total_len
    if len(env) < total_len:
        env.extend([0.0] * (total_len - len(env)))
    return env[:total_len]

# 1. Rope Cut Sound (0.16s: sharp noise transient + swoosh slice)
def gen_rope_cut():
    dur = 0.16
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    rnd = random.Random(42)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 26)  # fast decay
        # Frequency drop swoosh (850Hz -> 180Hz)
        freq = 850 - 670 * (t / dur)
        swoosh = math.sin(2 * math.pi * freq * t)
        # Snip noise
        noise = (rnd.random() * 2 - 1) * math.exp(-t * 50)
        sample = (0.55 * swoosh + 0.45 * noise) * env
        samples.append(sample * 0.9)
    return samples

# 2. Star Collect (0.35s: bright chime with bell harmonics)
def gen_star_collect():
    dur = 0.35
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    f1, f2, f3 = 1046.5, 1318.5, 2093.0  # C6, E6, C7
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 11)
        shimmer = 1.0 + 0.15 * math.sin(2 * math.pi * 14 * t)
        tone = (
            0.55 * math.sin(2 * math.pi * f1 * t) +
            0.30 * math.sin(2 * math.pi * f2 * t) +
            0.15 * math.sin(2 * math.pi * f3 * t)
        )
        samples.append(tone * env * shimmer * 0.8)
    return samples

# 3. Nom Nom / Monster Eat (0.30s: two cheerful chomps)
def gen_nom_nom():
    dur = 0.30
    n_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * n_samples
    rnd = random.Random(99)

    def add_chomp(start_t, chomp_dur):
        start_idx = int(start_t * SAMPLE_RATE)
        c_samples = int(chomp_dur * SAMPLE_RATE)
        for i in range(c_samples):
            idx = start_idx + i
            if idx >= n_samples:
                break
            t = i / SAMPLE_RATE
            env = math.exp(-t * 30)
            # Pitch slide down
            freq = 420 - 220 * (t / chomp_dur)
            tone = math.sin(2 * math.pi * freq * t)
            crunch = (rnd.random() * 2 - 1) * math.exp(-t * 45) * 0.4
            samples[idx] += (tone * 0.7 + crunch) * env * 0.8

    add_chomp(0.0, 0.13)
    add_chomp(0.14, 0.15)
    return samples

# 4. Level Complete Fanfare (1.25s: 4 ascending celebratory notes)
def gen_level_complete():
    dur = 1.25
    n_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * n_samples
    # C5, E5, G5, C6
    notes = [
        (0.00, 0.22, 523.25),
        (0.20, 0.22, 659.25),
        (0.40, 0.22, 783.99),
        (0.60, 0.65, 1046.50),
    ]
    for start_t, n_dur, freq in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        count = int(n_dur * SAMPLE_RATE)
        for i in range(count):
            idx = start_idx + i
            if idx >= n_samples:
                break
            t = i / SAMPLE_RATE
            # Attack and decay
            att = min(1.0, t / 0.015)
            dec = math.exp(-t * (4.5 if n_dur < 0.3 else 2.2))
            env = att * dec
            # Rich brassy harmonic
            tone = (
                0.60 * math.sin(2 * math.pi * freq * t) +
                0.25 * math.sin(2 * math.pi * (freq * 2) * t) +
                0.15 * math.sin(2 * math.pi * (freq * 3) * t)
            )
            samples[idx] += tone * env * 0.7
    return samples

# 5. Level Fail Sound (0.75s: comical downward slide with wobble)
def gen_level_fail():
    dur = 0.75
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 4.2)
        # Pitch sliding from 420Hz down to 140Hz
        freq = 420 - 280 * math.pow(t / dur, 0.7)
        # Wobble vibrato
        wobble = 1.0 + 0.2 * math.sin(2 * math.pi * 9 * t)
        tone = math.sin(2 * math.pi * freq * t + wobble)
        sub = 0.3 * math.sin(2 * math.pi * (freq * 0.5) * t)
        samples.append((tone * 0.7 + sub) * env * 0.8)
    return samples

# 6. Booster Activate (0.45s: magical rising shimmer power-up)
def gen_booster():
    dur = 0.45
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = min(1.0, t / 0.05) * math.exp(-t * 4.0)
        # Frequency sweep upwards
        freq = 280 + 900 * math.pow(t / dur, 1.4)
        shimmer = math.sin(2 * math.pi * 18 * t) * 0.2
        tone = (
            0.6 * math.sin(2 * math.pi * (freq + shimmer * 50) * t) +
            0.3 * math.sin(2 * math.pi * (freq * 1.5) * t) +
            0.1 * math.sin(2 * math.pi * (freq * 2.0) * t)
        )
        samples.append(tone * env * 0.8)
    return samples

# 7. Bubble Pop (0.08s: quick resonant hollow pop)
def gen_bubble_pop():
    dur = 0.08
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 55)
        # Plunge from 720Hz to 130Hz
        freq = 720 - 590 * (t / dur)
        tone = math.sin(2 * math.pi * freq * t)
        samples.append(tone * env * 0.9)
    return samples

# 8. UI Click (0.04s: wooden tactile blip)
def gen_ui_click():
    dur = 0.04
    n_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 85)
        tone = math.sin(2 * math.pi * 920 * t)
        samples.append(tone * env * 0.75)
    return samples

# 9. Main Theme BGM (8.0s: seamless looping cheerful marimba melody)
def gen_main_theme():
    bpm = 120
    dur = 8.0  # 16 beats = 4 bars
    n_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * n_samples
    beat_dur = 60.0 / bpm  # 0.5s per beat

    # Melody notes: (beat_index, note_freq, duration_beats)
    # Pentatonic melody in C Major: C4=261.63, D4=293.66, E4=329.63, G4=392.00, A4=440.00, C5=523.25, E5=659.25, G5=783.99
    melody = [
        (0.0, 523.25, 0.45), # C5
        (0.5, 659.25, 0.45), # E5
        (1.0, 783.99, 0.85), # G5
        (2.0, 659.25, 0.45), # E5
        (2.5, 523.25, 0.45), # C5
        (3.0, 587.33, 0.85), # D5
        (4.0, 523.25, 0.45), # C5
        (4.5, 659.25, 0.45), # E5
        (5.0, 880.00, 0.85), # A5
        (6.0, 783.99, 0.45), # G5
        (6.5, 659.25, 0.45), # E5
        (7.0, 587.33, 0.85), # D5
        (8.0, 659.25, 0.45), # E5
        (8.5, 783.99, 0.45), # G5
        (9.0, 1046.5, 0.85), # C6
        (10.0, 880.00, 0.45), # A5
        (10.5, 783.99, 0.45), # G5
        (11.0, 659.25, 0.85), # E5
        (12.0, 523.25, 0.45), # C5
        (12.5, 587.33, 0.45), # D5
        (13.0, 659.25, 0.85), # E5
        (14.0, 587.33, 0.85), # D5
        (15.0, 523.25, 0.85), # C5
    ]

    # Bassline notes: (beat_index, freq)
    bass = [
        (0.0, 130.81),  # C3
        (2.0, 196.00),  # G3
        (4.0, 174.61),  # F3
        (6.0, 196.00),  # G3
        (8.0, 130.81),  # C3
        (10.0, 220.00), # A3
        (12.0, 174.61), # F3
        (14.0, 196.00), # G3
    ]

    # Render melody (plucky marimba style)
    for beat_idx, freq, note_beats in melody:
        start_t = beat_idx * beat_dur
        start_idx = int(start_t * SAMPLE_RATE)
        note_samples = int(note_beats * beat_dur * SAMPLE_RATE)
        for i in range(note_samples):
            idx = (start_idx + i) % n_samples
            t = i / SAMPLE_RATE
            env = math.exp(-t * 6.5)
            # Marimba body: fundamental + weak 3rd harmonic
            tone = (
                0.60 * math.sin(2 * math.pi * freq * t) +
                0.25 * math.sin(2 * math.pi * (freq * 2.75) * t) +
                0.15 * math.sin(2 * math.pi * (freq * 4) * t)
            )
            samples[idx] += tone * env * 0.40

    # Render bass
    for beat_idx, freq in bass:
        start_t = beat_idx * beat_dur
        start_idx = int(start_t * SAMPLE_RATE)
        note_samples = int(1.8 * beat_dur * SAMPLE_RATE)
        for i in range(note_samples):
            idx = (start_idx + i) % n_samples
            t = i / SAMPLE_RATE
            env = math.exp(-t * 3.0)
            tone = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * (freq * 2) * t)
            samples[idx] += tone * env * 0.28

    # Render soft percussion tick on every beat
    rnd = random.Random(7)
    for b in range(16):
        start_idx = int(b * beat_dur * SAMPLE_RATE)
        tick_len = int(0.02 * SAMPLE_RATE)
        for i in range(tick_len):
            idx = (start_idx + i) % n_samples
            t = i / SAMPLE_RATE
            env = math.exp(-t * 120)
            noise = (rnd.random() * 2 - 1)
            samples[idx] += noise * env * 0.12

    # Smooth crossfade at loop boundaries (first and last 100ms) to eliminate any clicks
    fade_len = int(0.05 * SAMPLE_RATE)
    for i in range(fade_len):
        w = i / fade_len
        samples[i] *= w
        samples[n_samples - 1 - i] *= w

    return samples

if __name__ == '__main__':
    sfx_dir = os.path.join('assets', 'audio', 'sfx')
    music_dir = os.path.join('assets', 'audio', 'music')

    write_wav(os.path.join(sfx_dir, 'rope_cut.wav'), gen_rope_cut())
    write_wav(os.path.join(sfx_dir, 'star_collect.wav'), gen_star_collect())
    write_wav(os.path.join(sfx_dir, 'nom_nom.wav'), gen_nom_nom())
    write_wav(os.path.join(sfx_dir, 'level_complete.wav'), gen_level_complete())
    write_wav(os.path.join(sfx_dir, 'level_fail.wav'), gen_level_fail())
    write_wav(os.path.join(sfx_dir, 'booster_use.wav'), gen_booster())
    write_wav(os.path.join(sfx_dir, 'bubble_pop.wav'), gen_bubble_pop())
    write_wav(os.path.join(sfx_dir, 'ui_click.wav'), gen_ui_click())
    write_wav(os.path.join(music_dir, 'main_theme.wav'), gen_main_theme())
    print("All audio assets generated successfully!")

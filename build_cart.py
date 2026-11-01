"""Package editable Lua and the native sprite sheet into one PICO-8 cart."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HEADER = "pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n"


def graphics_section():
    rows = (ROOT / "ship.hex").read_text().splitlines()
    assert len(rows) == 16 and all(len(row) == 16 for row in rows)
    assert all(c in "0123456789abcdef" for row in rows for c in row)
    return "\n__gfx__\n" + "\n".join(row + "0" * 112 for row in rows) + "\n"


def audio_section():
    sounds = [[(0, 0, 0, 0)] * 32 for _ in range(17)]
    # Distinct laser sweeps: crisp normal zap, sustained triple charged zap.
    # ZAP-ZAP-ZAAAAAAP: two fast zips, then one sustained laser fade.
    sounds[1][:4] = [(42, 7, 6, 1), (22, 7, 0, 0),
                     (42, 7, 6, 1), (22, 7, 0, 0)]
    pitches = [54, 52, 50, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38,
               37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24]
    for n, pitch in enumerate(pitches):
        volume = 6 if n == 0 else (5 if n < 4 else (4 if n < 19 else (3 if n < 25 else 2)))
        sounds[1][n + 4] = (pitch - 12, 2 if n < 19 else 7, 0 if n == 27 else volume, 5 if n >= 25 else 1)
    for n in range(8):
        sounds[2][n] = (30 - n * 3, 6, max(0, 6 - n), 0)
    sounds[4][:6] = [(52, 7, 4, 1), (42, 7, 4, 1), (32, 7, 3, 1),
                     (24, 7, 2, 1), (18, 7, 1, 5), (16, 7, 0, 0)]
    for n in range(4):
        sounds[5][n] = (35 - n * 4, 6, 3 - n, 0)
    for n in range(10):
        sounds[6][n] = (max(5, 25 - n * 2), 6, max(0, 5 - n // 2), 0)
    for n in range(24):
        sounds[7][n] = (20 + n, 7, 1 if n < 7 else 2, 1)
    for n, pitch in enumerate([18, 18, 19, 19, 18, 18, 17, 17]):
        sounds[8][n] = (pitch, 0, 2, 1)
    # Four non-looping death layers: blast, sub-bass, tearing energy, debris.
    for n in range(16):
        sounds[9][n] = (max(3, 52 - n * 4), 6, max(0, 6 - n // 3), 3 if n == 0 else 0)
    for n in range(24):
        sounds[10][n] = (max(0, 23 - n * 2), 0, max(0, 5 - n // 5), 1)
    for n in range(16):
        sounds[11][n] = (max(8, 54 - n * 3), 7, max(0, 4 - n // 4), 1)
    for n, index in enumerate([1, 3, 6, 9, 13, 18]):
        sounds[12][index] = (max(10, 54 - n * 7), 6, max(1, 3 - n // 2), 3)
    # Title: sustained sub-bass beneath a quiet, dissonant, drifting overtone.
    # No noise waveform or rhythmic retrigger: this should hang in the air.
    for n in range(32):
        sounds[13][n] = (0, 0, 3, 0)
        pitch = [18, 18, 19, 19, 18, 18, 17, 18][n // 4]
        sounds[14][n] = (pitch, 0, 1, 1)
        # Thin high tension and a hollow tritone swell, staggered in the loop.
        sounds[15][n] = (42 + n // 8, 0, 1 if 8 <= n < 24 else 0, 4 if n == 8 else (5 if n == 23 else 1))
        sounds[16][n] = (6, 3, 1 if n >= 16 else 0, 4 if n == 16 else (5 if n == 31 else 0))
    rows = []
    for slot, notes in enumerate(sounds):
        speed = 5 if slot == 7 else (2 if slot == 4 else (3 if slot in (9, 11, 12) else (6 if slot == 8 else 4)))
        if slot >= 13:
            speed = 32
        loop_end = 32 if slot >= 13 else (8 if slot in (0, 8) else 0)
        header = f"00{speed:02x}00{loop_end:02x}"
        rows.append(header + "".join(f"{p:02x}{w:x}{v:x}{e:x}" for p, w, v, e in notes))
    return "\n__sfx__\n" + "\n".join(rows) + "\n"


def cartridge(code):
    return HEADER + code + graphics_section() + audio_section() + "\n__music__\n03 0d0e0f10\n"


def game_source():
    return "\n".join((ROOT / name).read_text(encoding="utf-8")
                     for name in ("tunnel.lua", "combat.lua", "hazards.lua"))


if __name__ == "__main__":
    source = game_source()
    output = cartridge("-- hyperdeath murder tube\n-- screaming down the death hole\n" + source)
    assert "#include" not in output
    (ROOT / "hyperdeath-murder-tube.p8").write_text(output, encoding="utf-8", newline="\n")
    print("Built hyperdeath-murder-tube.p8 with embedded code and native ship sprite.")

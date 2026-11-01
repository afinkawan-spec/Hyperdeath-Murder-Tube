"""Run native PICO-8 regression checks in an isolated workspace profile.

python check_game.py [path/to/pico8.exe]
"""
from pathlib import Path
import subprocess
import sys
import time
import re
from build_cart import cartridge, game_source

root = Path(__file__).resolve().parent
profile = root / ".pico-check"
profile.mkdir(exist_ok=True)
exe = Path(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else Path(
    "C:/Program Files (x86)/PICO-8/pico8.exe"
)
source = game_source()

def exclude_functions(code, names):
    blocks = re.split(r"(?=^function [a-z_][a-z_0-9]*\()", code, flags=re.M)
    return "\n".join(block for block in blocks
                     if not any(block.startswith(f"function {name}(") for name in names))


graphics = {"draw_ring", "fill_triangle", "draw_gate", "draw_ship", "draw_streaks",
            "draw_impact", "centered", "_draw", "combat_point", "draw_target",
            "draw_combat_band", "draw_combat_hud", "draw_hazards"}
logic_source = exclude_functions(source, graphics) + "\nfunction _draw() end\n"
visual_source = exclude_functions(source, {"choose_route", "add_sweep", "crossing_offsets",
    "protect_transition", "add_gate", "difficulty_stage"}) + '''
function choose_route() end
function add_gate(z)
 generated+=1
 add(gates,{z=z,a=0,base_a=0,turn=0,width=0.19,rib=false,rib_width=0.055,
  zone=1,gap=17,radius=1,stage=1,pattern=1,step=0})
end
'''

if "--budget" in sys.argv:
    cart = profile / "budget.p8"
    cart.write_text(cartridge(source + '\ncls(0) info() extcmd("screen",3,1)\n'), encoding="utf-8")
    started = time.time()
    process = subprocess.Popen([str(exe), "-home", str(profile), "-root_path",
                                str(profile), "-x", str(cart)], cwd=root,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        process.communicate(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()
        process.communicate()
    captures = [p for p in profile.glob("budget*.png") if p.stat().st_mtime >= started]
    if not captures:
        raise RuntimeError("No native code-budget capture; inspect cartridge limits")
    print(max(captures, key=lambda p: p.stat().st_mtime))
    sys.exit(0)

for name, code, result_name in (
    ("reset_seed", (root / "tests/reset_seed_checks.lua").read_text(), "reset_seed_result.txt"),
    ("reset_score", (root / "reset-score.p8").read_text().split("__lua__\n", 1)[1]
     + '\nassert(dget(0)==0 and dget(1)==0,"helper clears both score chunks")\nprinth("PASS","reset_score_result.txt",true)\n',
     "reset_score_result.txt"),
    ("reset_reload", logic_source + "\n" + (root / "tests/reset_reload_checks.lua").read_text(),
     "reset_reload_result.txt"),
    ("audio", logic_source + "\n" + (root / "tests/audio_checks.lua").read_text(),
     "audio_result.txt"),
    ("verify", logic_source + "\n" + (root / "tests/game_checks.lua").read_text(),
     "verify_result.txt"),
    ("reload", (root / "tests/persistence_checks.lua").read_text(),
     "persistence_result.txt"),
    ("ui_visual", visual_source + "\n" + (root / "tests/ui_visual.lua").read_text(),
     "ui_visual_result.txt"),
    ("shot_bounds_visual", visual_source + "\n" + (root / "tests/shot_bounds_visual.lua").read_text(),
     "shot_bounds_visual_result.txt"),
    ("shutter_visual", visual_source + "\n" + (root / "tests/shutter_visual.lua").read_text(),
     "shutter_visual_result.txt"),
    ("visual", visual_source + "\n" + (root / "tests/visual_checks.lua").read_text(),
     "visual_result.txt"),
    ("shutter_frequency", logic_source + "\n" + (root / "tests/shutter_frequency_checks.lua").read_text(),
     "shutter_frequency_result.txt"),
    ("patterns", logic_source + "\n" + (root / "tests/pattern_checks.lua").read_text(),
     "patterns_result.txt"),
    ("progression", logic_source + "\n" + (root / "tests/progression_checks.lua").read_text(),
     "progression_result.txt"),
    ("transitions", logic_source + "\n" + (root / "tests/transition_checks.lua").read_text(),
     "transition_result.txt"),
    ("charge", logic_source + "\n" + (root / "tests/charge_checks.lua").read_text(),
     "charge_result.txt"),
    ("combat", logic_source + "\n" + (root / "tests/combat_checks.lua").read_text(),
     "combat_result.txt"),
    ("combat_visual", visual_source + "\n" + (root / "tests/combat_visual.lua").read_text(),
     "combat_visual_result.txt"),
    ("hazards", logic_source + "\n" + (root / "tests/hazard_checks.lua").read_text(),
     "hazard_result.txt"),
    ("combos", logic_source + "\n" + (root / "tests/combo_checks.lua").read_text(),
     "combo_result.txt"),
    ("encounters", logic_source + "\n" + (root / "tests/encounter_checks.lua").read_text(),
     "encounter_result.txt"),
    ("encounter_visual", visual_source + "\n" + (root / "tests/encounter_visual.lua").read_text(),
     "encounter_visual_result.txt"),
):
    if "--only" in sys.argv and name != sys.argv[sys.argv.index("--only") + 1]:
        continue
    if not name.endswith("visual"):
        code = code.replace('extcmd("screen",3,1)', '')
    cart = profile / (name + ".p8")
    cart.write_text(cartridge(code), encoding="utf-8")
    result = profile / result_name
    result.write_text("NOT RUN", encoding="utf-8")
    if name == "audio":
        # Headless -x does not advance the audio mixer. Use a hidden, muted window.
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        command = [str(exe), "-home", str(profile), "-root_path", str(profile)]
        command += ["-windowed", "1", "-width", "128", "-height", "128", "-volume", "0", "-run", str(cart)]
        process = subprocess.Popen(command,
            cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, startupinfo=startup)
        deadline = time.monotonic() + 20
        try:
            while time.monotonic() < deadline and process.poll() is None:
                if result.read_text().strip() != "NOT RUN":
                    break
                time.sleep(0.05)
        finally:
            if process.poll() is None:
                process.kill()
            stdout, stderr = process.communicate()
        if result.read_text().strip() != "PASS":
            raise RuntimeError(f"{name} failed: {result.read_text()}\n{stdout!r}\n{stderr!r}")
    else:
        run = subprocess.run(
            [str(exe), "-home", str(profile), "-root_path", str(profile),
             "-x", str(cart)],
            cwd=root, capture_output=True, text=True, timeout=30,
        )
        if run.returncode or result.read_text().strip() != "PASS":
            raise RuntimeError(f"{name} failed: {run.stdout}\n{run.stderr}\n"
                               f"{result.read_text()}")
    print(f"PASS: {name}")

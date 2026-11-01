"""Capture README screenshots and enemy portraits using the actual PICO-8 renderer.
Requires PICO-8 and Pillow. Run from the project root.
"""
from pathlib import Path
import re
import subprocess
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build_cart import ROOT, cartridge, game_source
sys.path.insert(0, str(ROOT / ".media-capture/deps"))
from PIL import Image

profile = ROOT / ".media-capture"
profile.mkdir(exist_ok=True)
output = ROOT / "docs/images"
output.mkdir(parents=True, exist_ok=True)
remove = {"choose_route", "add_gate", "protect_transition", "crossing_offsets", "difficulty_stage"}
blocks = re.split(r"(?=^function [a-z_][a-z_0-9]*\()", game_source(), flags=re.M)
source = "\n".join(b for b in blocks if not any(b.startswith(f"function {name}(") for name in remove))
fixture = r'''
function choose_route() end
function add_gate(z)
 generated+=1
 add(gates,{z=z,a=0,base_a=0,turn=0,width=0.19,rib=false,rib_width=0.055,
  zone=1,gap=17,radius=1,pattern=1,step=0})
end
_init()
best=0 best_hi=0
_draw() extcmd("screen",3,1)
reset_run() mode="play" speed=1.12 angle=0.07 camera_angle=0.04
camera_cos=cos(-camera_angle) camera_sin=sin(-camera_angle)
visible_zone=2 shape_hex=0.7 tunnel_width=1
for i=1,#gates do
 local g=gates[i] g.z=15+(i-1)*18 g.a=0.06+(i-1)*0.035 g.zone=2
end
gates[2].rib=true gates[2].a=-0.09
gates[3].clocked=true gates[3].a=0.13
local e=spawn_pursuit("fighter") e.state="hunt" e.z=28 e.a=0.10
local b=spawn_pursuit("bomber") b.state="hunt" b.z=49 b.a=0.13
mines={{z=18,a=0.08,age=40},{z=32,a=0.12,age=40}}
shots={{z=8,a=0.07,power=3},{z=21,a=0.07}}
charge=30 points=2850 ticks=36
_draw() extcmd("screen",3,1)
-- Isolated, magnified portraits still use draw_target, including its pod geometry.
combat_point=function(z,a) return 64+a*110,64+(z-8)*1.4 end
camera_angle=0
for kind in all({"fighter","bomber","formation","gunship"}) do
 cls(0)
 if kind=="formation" then
  for i=-1,1 do draw_target({kind=kind,z=8+i*3,a=i*0.14,bank=0,hit=0}) end
 else
  draw_target({kind=kind,z=8,a=0,bank=0,hit=0,pods=kind=="gunship" and {3,3} or nil})
 end
 extcmd("screen",3,1)
end
printh("PASS","media_result.txt",true)
'''
cart = profile / "media.p8"
cart.write_text(cartridge(source + fixture), encoding="utf-8")
result = profile / "media_result.txt"
result.write_text("NOT RUN")
for old in profile.glob("media_*.png"):
    old.unlink()
exe = sys.argv[1] if len(sys.argv)>1 else "C:/Program Files (x86)/PICO-8/pico8.exe"
run = subprocess.run([exe,"-home",str(profile),"-root_path",str(profile),"-x",str(cart)],capture_output=True,text=True,timeout=30)
assert result.read_text().strip()=="PASS", run.stdout+run.stderr
captures = sorted(profile.glob("media_*.png"), key=lambda p: int(p.stem.rsplit("_",1)[1]))
assert len(captures)==6, captures
for name, capture in zip(["title","gameplay","fighter","bomber","formation","gunship"],captures):
    img=Image.open(capture).convert("RGB").resize((128,128),Image.Resampling.NEAREST)
    if name in ("title","gameplay"):
        img=img.resize((512,512),Image.Resampling.NEAREST)
    else:
        img=img.crop((40,40,88,88)).resize((192,192),Image.Resampling.NEAREST)
    img.save(output/(name+".png"))
print("Saved six native-rendered README images to docs/images")

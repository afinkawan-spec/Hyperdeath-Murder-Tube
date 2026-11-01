_init()
btn=function(n) return false end
btnp=function(n) return false end
local function clear_course()
 reset_run() mode="play" speed=0.5555556
 for g in all(gates) do g.z+=1000 end
end
-- Depth bands must hide targets behind opaque gate panels.
clear_course()
enemies={{kind="fighter",z=24,a=0.40,hp=3,max_hp=8,hit=0}}
gates[1].z=12 gates[1].a=0 gates[1].base_a=0
_draw()
local x,y=combat_point(enemies[1].z,enemies[1].a)
local target=enemies[1]
enemies={} _draw()
local baseline={}
for py=flr(y)-6,flr(y)+6 do
 for px=flr(x)-6,flr(x)+6 do add(baseline,pget(px,py)) end
end
enemies={target} _draw()
local sample=1
for py=flr(y)-6,flr(y)+6 do
 for px=flr(x)-6,flr(x)+6 do
  assert(pget(px,py)==baseline[sample],"barrier fully occludes target pixels")
  sample+=1
 end
end
gates[1].z=40
enemies[1].a=0 enemies[1].hit=0
shots={{z=8,a=0},{z=16,a=0}}
_draw() extcmd("screen",3,1)
-- Check a busy frame, including banked ship, effects, bullets, and target.
clear_course()
tunnel_width=1.10 visible_width=1.10 shape_hex=1 visible_zone=2
for i=1,#gates do
 gates[i].zone=2 gates[i].radius=1.10 gates[i].z=-3+(i-1)*17
end
enemies={{kind="fighter",z=20,a=0.1,hp=4,max_hp=8,hit=2}}
shots={{z=4,a=0.1},{z=10,a=0.1},{z=16,a=0.1}}
for i=1,3 do combat_effect(10+i*3,0.1,true) end
local before=stat(1)
_draw()
local cost=stat(1)-before
assert(cost<1,"combat frame stays within native draw budget")
printh("combat draw cpu "..cost,"combat_cost.txt",true)

clear_course()
gates[1].z=22 gates[1].a=0 gates[2].z=55 gates[2].a=0.1
enemies={{kind="bomber",z=26,a=0,hp=6,max_hp=6,hit=0,state="hunt"}}
for side=-1,1 do add(mines,{z=18,a=side*0.026,age=30}) end
shots={{z=7,a=0}}
_draw() extcmd("screen",3,1)
clear_course()
gates[1].z=35 gates[1].a=0
_draw() extcmd("screen",3,1)
hostile_bolts={{z=8,a=0.04},{z=16,a=0.1},{z=22,a=0.16}}
_draw() extcmd("screen",3,1)
clear_course()
tunnel_width=1.10 visible_width=1.10 shape_hex=1 visible_zone=2
for i=1,#gates do gates[i].zone=2 gates[i].radius=1.10 gates[i].z=-3+(i-1)*17 end
enemies={{kind="bomber",z=20,a=0.1,hp=4,max_hp=6,hit=0}}
for side=-1,1 do add(mines,{z=12,a=0.1+side*0.026,age=30}) end
hostile_bolts={{z=8,a=0.1},{z=16,a=0.16},{z=22,a=0.2}}
shots={{z=4,a=0.1},{z=10,a=0.1},{z=16,a=0.1}}
speed=max_speed
for i=1,3 do combat_effect(10+i*3,0.1,true) end
local before=stat(1)
_draw()
local cost=stat(1)-before
assert(cost<1,"all-threat draw stays within budget")
printh("all-threat draw cpu "..cost,"hazard_cost.txt",true)
printh("PASS","combat_visual_result.txt",true)

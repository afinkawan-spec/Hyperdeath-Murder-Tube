_init()
btn=function(n) return false end
btnp=function(n) return false end
local function scene()
 reset_run() mode="play" speed=0.5555556
 for i=1,#gates do gates[i].z=38+(i-1)*24 gates[i].a=0 end
end
scene() spawn_pursuit("formation")
for frame=1,300 do for e in all(enemies) do update_pursuit(e) end end
_draw() extcmd("screen",3,1)
mode="dead" speed=0.7
_draw() extcmd("screen",3,1)
scene() local ship=spawn_pursuit("gunship")
ship.state="hunt" ship.z=26 ship.a=0
_draw() extcmd("screen",3,1)
for i=1,3 do damage_target(ship,ship.a-0.065,3) end
for i=1,45 do ticks=(ticks+1)%240 update_combat() end
_draw() extcmd("screen",3,1)

scene() local fighter=spawn_pursuit("fighter")
fighter.state="hunt" fighter.z=30 fighter.a=0.06 fighter.attack_wait=1
angle=0.06 update_hazards()
for i=1,19 do update_hazards() end
_draw() extcmd("screen",3,1)
for i=1,25 do update_hazards() end
_draw() extcmd("screen",3,1)

scene() charge=60 fire_flash=7
shots={{z=4,a=0},{z=12,a=0,power=3},{z=24,a=0,power=3}}
_draw() extcmd("screen",3,1)

scene() spawn_pursuit("formation")
spawn_pursuit("formation") spawn_pursuit("formation")
for i=1,#enemies do
 local e=enemies[i] e.state="hunt" e.z=20+i*2 e.a=-0.12+i*0.03
end
tunnel_width=1.10 visible_width=1.10 shape_hex=1 visible_zone=2
for i=1,#gates do gates[i].zone=2 gates[i].radius=1.10 gates[i].z=-3+(i-1)*17 end
for side=-1,1 do add(mines,{z=12,a=0.1+side*0.026,age=30}) end
enemies[1].attack_age=20 enemies[1].aim=0.1
hostile_bolts={{z=8,a=0.1},{z=16,a=0.16},{z=22,a=0.2}}
shots={{z=4,a=0.1,power=3},{z=10,a=0.1,power=3},{z=16,a=0.1,power=3}}
speed=max_speed
for i=1,3 do combat_effect(10+i*3,0.1,true) end
local before=stat(1)
_draw()
local cost=stat(1)-before
assert(cost<1,"formation and all hazards fit draw budget")
printh("formation stress cpu "..cost,"encounter_cost.txt",true)
printh("PASS","encounter_visual_result.txt",true)

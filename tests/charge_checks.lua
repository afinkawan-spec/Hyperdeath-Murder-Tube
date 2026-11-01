_init()
local held={}
btn=function(n) return held[n] or false end
btnp=function(n) return false end
local function course()
 reset_run() mode="play" speed=0.5555556 enemy_wait=10000 held={}
 for g in all(gates) do g.z+=1000 end
end
course() update_combat() held[4]=true
for i=1,59 do update_combat() end
assert(charge==59 and #shots==0,"charge needs full hold")
held[4]=false update_combat()
assert(charge==0 and #shots==0,"early release adds no extra shot")
held[4]=true
for i=1,75 do update_combat() end
assert(charge==60 and #shots==0,"full charge waits for release")
held[4]=false update_combat()
assert(#shots==1 and shots[1].power==3 and fire_cooldown==11,"release fires one charged shot")
for i=1,10 do update_combat() end
assert(#shots==1,"release cannot repeat")
course() update_combat() held[4]=true
for i=1,60 do update_combat() end
fire_cooldown=5 held[4]=false update_combat()
assert((fire_pending==3) and #shots==0,"release buffers through cooldown")
for i=1,4 do update_combat() end
assert(#shots==1 and shots[1].power==3 and not (fire_pending==3),"buffered charge fires once")
-- Holding the title/retry button primes charge without a release or extra shot.
for starting in all({"title","dead"}) do
 for button=4,5 do
  course() mode=starting impact_age=45 retry_armed=true held[button]=true
  btnp=function(n) return held[n] or false end
  _update60()
  assert(mode=="play","starting run arms held fire")
  for i=1,60 do _update60() end
  assert(charge==60 and #shots==0,"held start button charges without unwanted normal shot")
  held[button]=false _update60()
  assert(#shots==1 and shots[1].power==3,"release after held start fires charged shot")
 end
end
btnp=function(n) return false end

-- X mirrors Z, including charging and combined-button handoffs.
course() update_combat() held[5]=true update_combat()
assert(#shots==1 and shots[1].power==1,"X press fires normal shot")
for i=1,59 do update_combat() end
assert(charge==60,"X hold fully charges")
held[5]=false update_combat()
assert(#shots==1 and shots[1].power==3,"X release fires charged shot")
course() update_combat() held[4]=true update_combat()
held[5]=true update_combat() held[4]=false update_combat()
assert(#shots==1 and charge==3,"button handoff does not double-fire or release charge")
held[5]=false update_combat()
assert(charge==0 and #shots==1,"releasing both buttons ends short hold")

course() shots={{z=0,a=0,power=1},{z=0,a=0,power=3}}
update_combat()
assert(shots[1].z<shots[2].z,"charged projectile travels faster than normal")

course() local e=spawn_pursuit("fighter") e.state="hunt" e.z=26
shots={{z=25,a=e.a,power=3}} update_combat()
assert(e.hp==9,"charged shot deals triple damage")
course() e=spawn_pursuit("fighter") e.z=20 e.a=0.99 e.state="hunt"
assert(not shot_victim({z=21,a=0.05},19,1000),"normal shot misses wide angle")
assert(shot_victim({z=21,a=0.05,power=3},19,1000)==e,"charged shot has wider wrapped collision")
course() e=spawn_pursuit("gunship")
damage_target(e,e.a,3)
assert(e.hp==6,"charged shot still glances off centre armour")
damage_target(e,e.a+0.065)
assert(e.hp==6 and e.pods[2]==3,"normal fire cannot damage gunship pods")
e.hp=5 e.pods[2]=2
damage_target(e,e.a+0.11,3)
assert(e.hp==3 and e.pods[2]==0 and not e.dead,"wide triple shot clamps to remaining pod health")
damage_target(e,e.a-0.065,3)
assert(e.dead and kills==1 and points==1500,"triple shot finishes remaining pod")
course() local g=gates[1] g.z=3 g.a=0
shots={{z=2,a=0.17,power=3}}
assert(not gate_blocks(g,0.17),"shot centre fits opening")
update_combat()
assert(#shots==0,"wide shot edge cannot pass through barrier")
course() mines={{kind="mine",z=12,a=0,age=30},{kind="mine",z=12,a=0.026,age=30}}
shots={{z=11,a=0,power=3}} update_combat()
assert(#mines==0 and points==100 and #shots==1,"charged shot directly pierces both mines")
-- Two targets in the same frame and later frames are all hit once.
course()
local a=spawn_pursuit("fighter") a.state="hunt" a.z=26
local b=spawn_pursuit("fighter") b.state="hunt" b.z=27
shots={{z=25,a=0,power=3}}
update_combat()
assert(a.hp==9 and b.hp==9 and #shots==1,"charged shot pierces multiple ships in one step")
local c=spawn_pursuit("fighter") c.state="hunt" c.z=34
for i=1,3 do update_combat() end
assert(a.hp==9 and b.hp==9 and c.hp==9,"same shot hits a further ship without repeating damage")
-- Even a target that re-enters the swept segment cannot be hit twice.
local packet=shots[1]
a.z=packet.z+1 a.a=packet.a
update_combat()
assert(a.hp==9,"one hit per target per charged shot")
course()
a=spawn_pursuit("fighter") a.state="hunt" a.z=26
b=spawn_pursuit("fighter") b.state="hunt" b.z=27
shots={{z=25,a=0}} update_combat()
assert(a.hp==11 and b.hp==12 and #shots==0,"normal shots still stop at first ship")
-- Freeze target steering to isolate projectile depth/occlusion at a wall.
local move=update_pursuit
update_pursuit=function(e) end
-- Killing a ship before a wall does not allow the shot through that wall.
course()
a=spawn_pursuit("fighter") a.state="hunt" a.z=26 a.hp=3
b=spawn_pursuit("fighter") b.state="hunt" b.z=27.5
local wall=gates[1] wall.z=27 wall.a=0.4
shots={{z=25,a=0,power=3}} update_combat()
assert(a.dead and b.hp==12 and #shots==0,"barrier stops charged shot after front target")
course()
a=spawn_pursuit("fighter") a.state="hunt" a.z=26
b=spawn_pursuit("fighter") b.state="hunt" b.z=27.5
wall=gates[1] wall.z=27 wall.a=0 wall.rib=true
shots={{z=25,a=0,power=3}} update_combat()
assert(a.hp==9 and b.hp==12 and #shots==0,"rib also stops piercing shot")

update_pursuit=move
reset_run()
assert(charge==0 and not (fire_pending==3),"restart clears charge")
printh("PASS","charge_result.txt",true)

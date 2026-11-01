_init()
local held={}
btn=function(n) return held[n] or false end
btnp=function(n) return held[n] or false end
local function course()
 reset_run() mode="play" speed=0.5555556 held={}
 for g in all(gates) do g.z+=1000 end
end

course() crash_player(nil,"mine") held[4]=true
for i=1,44 do _update60() assert(mode=="dead","three-quarter-second retry lockout") end
_update60() assert(mode=="dead","held fire cannot restart after lockout")
held[4]=false _update60()
held[4]=true _update60()
assert(mode=="play","fresh press restarts after lockout")

course()
spawn_pursuit("bomber")
assert(enemies[1] and enemies[1].kind=="bomber" and enemies[1].hp==6,"bomber encounter")
enemies[1].state="hunt" enemies[1].z=26
local first=gates[1] first.previous_z=27 first.z=25 first.a=0.2
update_combat()
assert(#mines==0 and enemies[1].drops==1,"one gate before payload")
local second=gates[2] second.previous_z=27 second.z=25 second.a=0.25
update_combat()
assert(#mines==1 and enemies[1].drops==2,"first bomb at second opening")
first.previous_z=nil second.previous_z=nil
for i=1,29 do update_combat() end
assert(#mines==1,"half second delay before second bomb")
update_combat() assert(#mines==2,"second bomb after half second")
for i=1,30 do update_combat() end
assert(#mines==2 and not enemies[1].payload,"third bomb after another half second")
assert(mines[2].z-mines[1].z>6,"bombs separated along tunnel")
local bomber=enemies[1]
for i=1,6 do damage_target(bomber) end
assert(enemies[1].dead and kills==1,"shoot down bomber")
update_combat() assert(#mines==2,"bomber death stops new payloads")

-- Bombs coast forward, holding a 500 km/h closing speed at either cruise speed.
for cruise in all({0.6481481,max_speed}) do
 course() speed=cruise drop_mines({z=40,a=0})
 update_hazards()
 assert(abs((40-mines[1].z)*1080-500)<0.03,"bomb closing speed")
 assert(40-mines[1].z<speed,"bomb travels forward slower than player")
end

-- Each bomber independently remembers an opening it crossed.
course()
local one=spawn_pursuit("bomber") local two=spawn_pursuit("bomber")
one.state="hunt" two.state="hunt" one.z=26 two.z=26
local shared=gates[1] shared.previous_z=27 shared.z=25
update_pursuit(one) update_pursuit(two)
assert(one.drops==1 and two.drops==1,"overlapping bombers both count the opening")
update_pursuit(one) update_pursuit(two)
assert(one.drops==1 and two.drops==1,"same opening cannot count twice for either bomber")

course()
mines={{kind="mine",z=12,a=0,age=30},
 {kind="mine",z=13,a=0.02,age=30},
 {kind="mine",z=14,a=-0.02,age=30},
 {kind="mine",z=24,a=0.3,age=30}}
shots={{z=11,a=0}}
update_combat()
assert(#mines==3 and points==50 ,"direct hit destroys only one bomb")
assert(mode=="play","shot bomb blast does not hurt player")

course() mines={{kind="mine",z=0.1,a=0,age=30}}
update_combat()
assert(mode=="dead" and impact_type=="mine","armed mine collision")
course() mines={{kind="mine",z=0.1,a=0,age=30}}
held[4]=true update_combat()
assert(mode=="play" and #mines==0 and points==50,"last-instant defuse")

-- Lone fighter uses a locked warning, then three projectiles.
course() local e=spawn_pursuit("fighter")
e.state="hunt" e.z=50 e.attack_wait=1
update_hazards()
assert(e.attack_age==1 and e.aim==angle and #hostile_bolts==0,"fighter begins warning")
angle=0.2
for i=1,58 do update_hazards() end
assert(#hostile_bolts==0,"full warning before fighter burst")
update_hazards()
assert(#hostile_bolts==1 and hostile_bolts[1].aim==0,"fighter locks announced aim")
for i=1,16 do update_hazards() end
assert(#hostile_bolts==3 and not e.attack_age,"three shots finish burst")
assert(e.attack_wait>200,"fighter rests between bursts")

course() e=spawn_pursuit("fighter") e.state="hunt" e.attack_wait=1
update_hazards()
for i=1,12 do damage_target(e,e.a) end
for i=1,60 do update_hazards() end
assert(#hostile_bolts==0,"kill during warning stops burst")

-- Intact gunship shoots; first lost pod cancels its burst and changes weapon.
course() e=spawn_pursuit("gunship") e.state="hunt" e.z=50 e.attack_wait=1 e.mine_wait=10000
update_hazards()
assert(e.attack_age==1 and not e.attack_bomb,"intact gunship warns for burst")
for i=1,3 do damage_target(e,e.a-0.065,3) end
assert(not e.attack_age and e.attack_wait==60 and #mines==0,"pod loss cancels pending burst")
for i=1,178 do update_hazards() end
assert(#mines==0 and e.attack_bomb,"damaged gunship warns before bomb")
update_hazards()
assert(#mines==1 and #hostile_bolts==0 and not e.attack_age,"damaged gunship drops bomb instead of burst")
hazard_collisions()
assert(mode=="play","new ship bomb has valid collision history")
for i=1,3 do damage_target(e,e.a+0.065,3) end
for i=1,500 do update_hazards() end
assert(#mines==1 and #hostile_bolts==0,"dead gunship cannot attack")

-- Formations can use either weapon, but cannot warn together.
course() spawn_pursuit("formation")
local random=rnd
rnd=function(n) return n*0.25 end
for f in all(enemies) do f.state="hunt" f.z=50 f.attack_wait=1 end
update_hazards()
assert(enemies[1].attack_age==1 and enemies[1].attack_bomb,"formation bomb choice")
assert(not enemies[2].attack_age and not enemies[3].attack_age,"global attack spacing")
for i=1,59 do update_hazards() end
assert(#mines==1 and enemies[1].attack_wait>400,"sparse formation bomb")
course() e=spawn_pursuit("formation")
e=enemies[1] e.state="hunt" e.z=50 e.attack_wait=1
rnd=function(n) return n*0.75 end
update_hazards()
assert(not e.attack_bomb,"formation burst choice")
for i=1,75 do update_hazards() end
assert(#hostile_bolts==3,"formation fires warned burst")
rnd=random

course()
hostile_bolts={{z=0.1,a=0,start_z=10,mount=0,aim=0}}
update_combat()
assert(mode=="dead" and impact_type=="bolt","ship bolt collision")
course() angle=0.1
hostile_bolts={{z=0.1,a=0,start_z=10,mount=0,aim=0}}
update_combat()
assert(mode=="play" and #hostile_bolts==0,"steer clear of locked line")
course() local wall=gates[1] wall.z=10 wall.a=0
hostile_bolts={{z=12,a=0.4,start_z=20,mount=0.4,aim=0.4}}
for i=1,12 do
 for g in all(gates) do g.z-=speed end
 update_hazards()
end
assert(hostile_bolts[1].dead,"solid barrier stops enemy bolt")

course() speed=max_speed
spawn_pursuit("bomber")
local previous_z=enemies[1].z
update_pursuit(enemies[1])
assert(enemies[1].z<previous_z,"high-speed bomber entry starts at correct depth")
for i=1,53 do update_pursuit(enemies[1]) end
previous_z=enemies[1].z update_pursuit(enemies[1])
assert(abs(enemies[1].z-previous_z)<0.1,"entry joins hunt without teleport")
assert(enemies[1].z/speed>=41.9,"mine drops retain high-speed reaction time")
printh("PASS","hazard_result.txt",true)

_init()
btn=function(n) return false end
btnp=function(n) return false end
local function course()
 reset_run() mode="play" speed=0.5555556 enemy_wait=10000
 for g in all(gates) do g.z+=1000 end
end
course() spawn_pursuit("formation")
assert(#enemies==3,"three scheduled fighters")
for e in all(enemies) do assert(e.hp==4,"four-hit fighters") end
assert(enemies[2].age==-90 and enemies[3].age==-180,"1.5 second arrival intervals")
assert(shot_victim({a=enemies[2].a,z=66},62,1000)==nil,"pending fighter cannot be shot")
for i=1,90 do update_combat() end
assert(enemies[1].state=="hunt" and enemies[2].age==0,"first arrives alone")
update_combat()
assert(enemies[2].age==1 and enemies[3].age==-89,"second arrival")
for i=1,90 do update_combat() end
assert(enemies[3].age==1,"third arrival")
for i=1,119 do update_combat() end
assert(enemies[2].z-enemies[1].z>5 and enemies[3].z-enemies[2].z>5,"independent depths")
for e in all(enemies) do
 for hit=1,3 do damage_target(e,e.a) assert(not e.dead,"survives three hits") end
 damage_target(e,e.a)
end
assert(kills==3 and points==1100 and enemies[1].group.kills==3,"full formation clear bonus")
update_combat() assert(#enemies==0,"destroyed fighters leave encounter")
course() spawn_pursuit("formation")
enemies[1].dead=true
for i=2,3 do
 for hit=1,4 do damage_target(enemies[i],enemies[i].a) end
end
assert(points==400 and enemies[2].group.kills==2,"missing member forfeits clear bonus")

course() spawn_pursuit("formation")
local old_group=enemies[1].group
spawn_pursuit("formation")
for i=1,2 do for hit=1,4 do damage_target(enemies[i],enemies[i].a) end end
for hit=1,4 do damage_target(enemies[4],enemies[4].a) end
assert(points==600 and old_group.kills==2,"overlapping groups keep separate bonuses")
for hit=1,4 do damage_target(enemies[3],enemies[3].a) end
assert(points==1300,"original group still earns clear bonus")

course() local ship=spawn_pursuit("gunship")
assert(ship.pods[1]==3 and ship.pods[2]==3,"independent engine armour")
damage_target(ship,ship.a)
assert(ship.hp==6 and ship.pods[1]==3,"hull hit glances harmlessly")
for i=1,3 do damage_target(ship,ship.a-0.065,3) end
assert(ship.pods[1]==0 and ship.pods[2]==3 and ship.hp==3 and not ship.dead,
 "one destroyed engine leaves gunship flying")
ship.state="hunt" ship.z=32
for i=1,60 do update_pursuit(ship) end
assert(ship.lane_target<0 and ship.lane_offset<0,"broken engine causes drift")
local hp=ship.hp
damage_target(ship,ship.a-0.065,3)
assert(ship.hp==hp,"destroyed pod cannot damage remaining engine")
for i=1,3 do damage_target(ship,ship.a+0.065,3) end
assert(ship.dead and ship.pods[2]==0 and kills==1 and points==1500,
 "both engines finish gunship")

course() mines={{kind="mine",z=12,a=0,age=30},{kind="mine",z=12,a=0.026,age=30}}
shots={{z=11,a=0}}
update_combat()
assert(#mines==1 and points==50,"neighbouring bomb survives direct hit")
printh("PASS","encounter_result.txt",true)

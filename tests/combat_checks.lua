_init()
local held={}
btn=function(n) return held[n] or false end
btnp=function(n) return false end
local function course()
 reset_run() mode="play" speed=0.5555556 held={}
 for g in all(gates) do g.z+=1000 end
end
course() fire_down=true held[4]=true update_combat()
assert(#shots==0 and charge==1,"held start charges without an extra normal shot")
held[4]=false update_combat()
held[4]=true update_combat()
assert(#shots==1 and fire_cooldown==11,"press fires one packet")
for i=1,30 do update_combat() end
assert(#shots==0 and fire_cooldown==0,"holding cannot repeat")
held[4]=false update_combat() held[4]=true update_combat()
held[4]=false update_combat() held[4]=true update_combat()
for i=1,8 do update_combat() end
assert(#shots==1,"cooldown limits queued press")
update_combat() assert(#shots==2,"one buffered press fires at cooldown end")

course()
gates[1].z=3 gates[1].a=0.4 gates[1].base_a=0.4
local e=spawn_pursuit("fighter")
e.z=4 e.a=0 e.state="hunt"
shots={{z=2,a=0}}
update_combat()
assert(#shots==0 and e.hp==12,"wall blocks shot")
course() e=spawn_pursuit("fighter")
for i=1,12 do
 shots={{z=e.z-1,a=e.a}}
 update_combat()
 if i<12 then assert(e.hp==12-i,"hit damages hull") end
end
assert(#enemies==0 and kills==1 and points==1000,"fighter kill reward")
course() e=spawn_pursuit("fighter")
e.state="hunt" e.z=26
for i=1,8000 do update_pursuit(e) end
assert(not e.dead and e.state=="hunt","no enemy timeout")
enemy_wait=1 update_combat()
assert(#enemies>1 and enemies[1]==e,"encounters overlap")
assert(enemy_wait>=300 and enemy_wait<=480,"five to eight second arrivals")

course()
local kinds={}
for i=1,50 do
 enemies={} enemy_wait=1 update_combat()
 kinds[enemies[1].kind]=true
end
assert(kinds.fighter and kinds.formation and kinds.bomber and kinds.gunship,"weighted random variety")
course() enemy_wait=1
for i=1,4500 do update_combat() end
assert(#enemies>=7 and #enemies<=9,"persistent swarm within render capacity")

srand(42) reset_run() mode="play" speed=0.5555556 enemy_wait=10000 held={}
spawn_pursuit("fighter")
update_hazards=function() end
hazard_collisions=function() end
for frame=1,1400 do
 held[4]=frame%12==0
 local target=nil
 for g in all(gates) do if g.z>0 then target=g break end end
 local aim=target.a
 if target.rib then
  aim=(aim+(turn_delta(angle,aim)>=0 and 0.115 or -0.115))%1
 elseif enemies[1] and clearance_at(target,enemies[1].a)>0.04 then
  aim=enemies[1].a
 end
 local error=turn_delta(aim,angle)-velocity*5
 held[0]=error<-0.001 held[1]=error>0.001
 _update60()
 assert(mode=="play","steering and combat remain compatible")
 if kills>0 then break end
end
assert(kills>0,"manual fire can win before hidden timeout")
course() srand(99) e=spawn_pursuit("fighter") e.state="hunt" e.z=26
local left,right=false,false
local previous=0
for i=1,500 do
 update_pursuit(e)
 assert(abs(e.lane_offset)<0.071,"small lane offset")
 assert(abs(e.lane_offset-previous)<0.0065,"smooth lane change")
 left=left or e.lane_offset<-0.02 right=right or e.lane_offset>0.02
 previous=e.lane_offset
end
assert(left and right,"fighter visits both sides")
printh("PASS","combat_result.txt",true)

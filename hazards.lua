-- Direct-hit bombs and warned ship attacks.
function gate_blocks(g,a)
 local d=abs(turn_delta(a,g.a))
 return g.rib and d<g.rib_width+0.005
  or (not g.rib and d>g.width-0.005)
end

function drop_mines(g)
 if #mines>=12 then return end
 add(mines,{kind="mine",z=g.z,old_z=g.z,a=g.a,age=0})
 combat_effect(g.z,g.a,false)
end

function detonate_mine(m)
 if m.dead then return end
 m.dead=true
 combat_effect(m.z,m.a,false)
 award_points(50)

end

function update_hazards()
 for m in all(mines) do
  m.old_z=m.z m.age+=1
  m.z-=0.4629630 -- Player closes on forward-moving bombs at 500 km/h.
 end
 attack_gap=max(0,attack_gap-1)
 for e in all(enemies) do
  if not e.dead and e.state=="hunt" and e.kind!="bomber" then update_attack(e) end
 end
 for b in all(hostile_bolts) do
  b.old_z=b.z b.z-=(speed+0.8)*0.65
  local progress=mid(0,1-b.z/max(1,b.start_z),1)
  b.a=(b.mount+turn_delta(b.aim,b.mount)*progress)%1
  for g in all(gates) do
   if g.z>0 and g.z>=b.z and g.z<=b.old_z-speed
    and gate_blocks(g,b.a) then b.dead=true end
  end
 end
end

function hazard_collisions()
 for list in all({mines,hostile_bolts}) do
  local mine=list==mines
  for h in all(list) do
   if not h.dead and h.old_z>0 and h.z<=0 and (not mine or h.age>=18)
    and abs(turn_delta(angle,h.a))<(mine and 0.02 or 0.018)+0.025/tunnel_width then
    crash_player(nil,mine and "mine" or "bolt") return
   end
  end
  for h in all(list) do if h.dead or h.z<0 then del(list,h) end end
 end
end

function shot_victim(shot,old_z,wall)
 local victim=nil
 for list in all({enemies,mines}) do
  for v in all(list) do
   if not v.dead and not (shot.hit and shot.hit[v]) and (v.state!="enter" or v.age>0) and v.z>=old_z and v.z<=shot.z and v.z<wall
    and abs(turn_delta(shot.a,v.a))<(v.kind=="gunship" and 0.105 or (v.kind=="mine" and 0.03 or 0.045))+(shot.power==3 and 0.035 or 0) then
    victim=v wall=v.z
   end
  end
 end
 return victim
end

function damage_target(v,aim,power)
 local damage=power or 1
 if v.kind=="mine" then
  detonate_mine(v) sfx(6,3)
  return
 end
 if v.kind=="gunship" then
  local d=turn_delta(aim or v.a,v.a)
  local side=d<0 and 1 or 2
  if power!=3 or abs(abs(d)-0.065)>0.025+0.035 or v.pods[side]==0 then
   combat_effect(v.z,aim or v.a,false) sfx(5,2) return
  end
  damage=min(damage,v.pods[side])
  v.pods[side]-=damage
  if v.pods[side]==0 then
   combat_effect(v.z,aim,true) v.attack_age=nil v.attack_wait=60
  end
 end
 v.hp-=damage v.hit=5
 combat_effect(v.z,v.a,false) sfx(5,2)
 if v.hp>0 then return end
 combat_effect(v.z,v.a,true) kills+=1
 v.dead=true
 local small=v.kind=="formation"
 award_points(small and 200 or (v.kind=="gunship" and 1500 or 1000))
 if small then
  v.group.kills+=1
  if v.group.kills==3 then award_points(500) end
 end
 sfx(6,3)
end

function draw_hazards(near,far)
 for m in all(mines) do
  if not m.dead and m.z>near and m.z<=far then
   local x,y=combat_point(m.z,m.a)
   local s=mid(1,70/(m.z+10),5)
   local col=m.age<18 and 9 or (ticks%12<6 and 8 or 10)
   line(x-s,y,x,y-s,col) line(x,y-s,x+s,y,col)
   line(x+s,y,x,y+s,col) line(x,y+s,x-s,y,col)
   pset(x,y,7)
  end
 end
 for e in all(enemies) do
  if e.attack_age and not e.dead then
   if e.z>near and e.z<=far then
    local x,y=combat_point(e.z,e.a)
    circ(x,y,5,e.attack_bomb and 9 or 10)
   end
   if not e.attack_bomb and e.attack_age<60 and ticks%8<5 then
    for i=1,3 do
     local z=e.z*i/4
     if z>near and z<=far then
      local x,y=combat_point(z,e.aim) line(x-1,y,x+1,y,10)
     end
    end
   end
  end
 end
 for b in all(hostile_bolts) do
  if not b.dead and b.z>near and b.z<=far then
   local x,y=combat_point(max(0,b.z),b.a)
   local bx,by=combat_point(max(0,b.z+2),b.a)
   line(bx,by,x,y,8) circfill(x,y,1,9) pset(x,y,7)
  end
 end
end

function update_attack(e)
 if e.pods then
  e.mine_wait=(e.mine_wait or 150)-1
  if e.mine_wait<=0 then drop_mines(e) e.mine_wait=180 end
 end
 e.attack_wait=(e.attack_wait or 240)-1
 if not e.attack_age and e.attack_wait<=0 and attack_gap==0 then
  e.attack_bomb=e.pods and (e.pods[1]==0 or e.pods[2]==0)
   or (e.kind=="formation" and rnd(1)<0.5)
  e.aim=angle e.attack_age=0 attack_gap=120
  e.attack_wait=e.kind=="formation" and 540+rnd(240) or 300+rnd(120)
 end
 if not e.attack_age then return end
 e.attack_age+=1
 if e.attack_age>=60 then
  if e.attack_bomb then
   drop_mines(e) e.attack_age=nil
  else
   if (e.attack_age-60)%8==0 and #hostile_bolts<9 then
    add(hostile_bolts,{z=e.z,a=e.a,start_z=e.z,mount=e.a,aim=e.aim})
   end
   if e.attack_age>=76 then e.attack_age=nil end
  end
 end
end

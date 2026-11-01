function flight_line(z)
 local prev_z=0
 local prev_a=route_anchor
 for g in all(gates) do
  if g.z>0 then
   local a=g.a
   if g.rib then a=(a+0.13)%1 end
   if z<=g.z then
    local t=mid(0,(z-prev_z)/(g.z-prev_z),1)
    t=t*t*(3-2*t)
    return (prev_a+turn_delta(a,prev_a)*t)%1,
     mid(0,min(z-prev_z,g.z-z)/8,1)
   end
   prev_z=g.z prev_a=a
  end
 end
 return prev_a,1
end

function safe_enemy_angle(z,a,margin)
 for g in all(gates) do
  local distance=abs(g.z-z)
  if g.z>0 and distance<8 then
   local d=turn_delta(a,g.a)
   local safe=d
   if g.rib then
    local bound=g.rib_width+margin
    if abs(d)<bound then safe=d>=0 and bound or -bound end
   else
    local bound=g.width-margin
    safe=mid(-bound,d,bound)
   end
   a=(a+(safe-d)*(1-distance/8))%1
  end
 end
 return a
end

function enemy_stand(e)
 if e.kind=="bomber" then return max(26,(speed+0.04)*42) end
 if e.kind=="gunship" then return 38 end
 return 32+(e.kind=="formation" and (e.slot+1)*9 or 0)
end

function spawn_pursuit(kind)
 local group={kills=0}
 kind=kind or "fighter"
 for i=1,kind=="formation" and 3 or 1 do
  local slot=kind=="formation" and i-2 or 0
  local hp=kind=="formation" and 4 or (kind=="fighter" and 12 or 6)
  local e={hp=hp,max_hp=hp,kind=kind,slot=slot,
   attack_wait=(kind=="formation" and 420 or 180)+rnd(180),group=group,side=i%2==0 and -1 or 1,drops=0,hit=0,state="enter",age=-(i-1)*90,lane_offset=slot*0.06}
  if kind=="gunship" then e.pods={3,3} end
  e.z=enemy_stand(e)+28 e.a=flight_line(e.z)
  add(enemies,e)
 end
 return enemies[#enemies]
end

function update_pursuit(e)
 local previous_z=e.z
 e.hit=max(0,e.hit-1) e.age=(e.age or 0)+1
 if e.age<=0 then return end
 local state=e.state or "hunt"
 if state=="hunt" then e.age%=7200 end
 local flourish=0
 local stand=enemy_stand(e)
 local broken=e.pods and (e.pods[1]==0 or e.pods[2]==0)
 if state=="enter" then
  local t=min(1,e.age/54)
  e.z=stand+28*(1-t)*(1-t)
  flourish=(e.side or 1)*(e.kind=="gunship" and 0.14 or 0.28)*sin(t/2)*(1-t)
  if t>=1 then e.state="hunt" e.age=0 end
 else
  e.z+=(stand+(e.kind=="fighter" and 7*sin(e.age/240) or 0)-e.z)*0.08
  if e.kind!="bomber" then
   flourish=0.035*sin(e.age/100)
   e.lane_timer=(e.lane_timer or 0)-1
   if e.lane_timer<=0 then
    e.lane_timer=45+flr(rnd(75))
    local side=(e.lane_target or 0)>=0 and -1 or 1
    if rnd(1)<0.25 then side=-side end
    e.lane_target=side*(e.kind=="formation" and (0.075+rnd(0.055)) or (0.045+rnd(0.025)))
   end
   if broken then
    e.lane_target=e.pods[1]==0 and -0.09 or 0.09
    flourish=0.03*sin(e.age/20)
   end
   e.lane_offset+=(e.lane_target-e.lane_offset)*(e.kind=="gunship" and 0.015 or 0.045)
  end
  if e.pods then e.lane_offset=broken and e.lane_offset or 0.1*sin(e.age/300) end
 end
 local line,room=flight_line(e.z)
 local a=safe_enemy_angle(e.z,(line+e.lane_offset+flourish*room)%1,
  e.kind=="gunship" and 0.10 or 0.045)
 e.bank=mid(-1,turn_delta(a,e.a)*160,1) e.a=a
 if e.kind=="bomber" and state=="hunt" then
  for g in all(gates) do
   if g.previous_z and g.previous_z>previous_z and g.z<=e.z
    and not g.rib and not g.clocked and e.last_drop_gate!=g then
    e.last_drop_gate=g e.drops+=1
    if e.drops%2==0 and not e.payload then e.payload=3 e.bomb_clock=0 end
   end
  end
 end
 if e.payload then
  e.bomb_clock-=1
  if e.bomb_clock<=0 then
   drop_mines({z=e.z,a=line}) e.payload-=1 e.bomb_clock=30
   if e.payload==0 then e.payload=nil e.peel=90 end
  end
 end
 if e.peel and e.peel>0 then e.peel-=1 e.lane_offset=0.11*(e.side or 1)
 elseif e.kind=="bomber" then e.lane_offset=0 end
 if e.hp<e.max_hp and e.hp<=3 and ticks%12==0 then
  combat_effect(e.z,e.a+(broken and (e.pods[1]==0 and -0.065 or 0.065) or 0),false)
 end
end

function update_combat()
 fire_flash=max(0,fire_flash-1) fire_cooldown=max(0,fire_cooldown-1)
 for fx in all(combat_fx) do
  fx.age+=1 fx.z-=speed
  if fx.age>=fx.life or fx.z<0 then del(combat_fx,fx) end
 end
 for e in all(enemies) do if not e.dead then update_pursuit(e) end end
 enemy_wait-=1
 if enemy_wait<=0 then
  if #enemies<7 then
   spawn_pursuit(rnd({"formation","formation","bomber","fighter","fighter","gunship"}))
  end
  enemy_wait=300+flr(rnd(181))
 end
 update_hazards()
 local blasting=stat(47)==1
 local down=btn(4) or btn(5)
 local pressed=down and not fire_down
 fire_down=down
 if pressed then fire_pending=fire_pending or 1 end
 if down then
  if charge>=8 and charge<59 and not blasting and stat(47)!=7 then sfx(7,1) end
  if charge>=59 and not blasting and stat(47)!=8 then sfx(8,1) end
  charge=min(60,charge+1)
 else
  if charge==60 then fire_pending=3
  elseif charge>8 and not blasting then sfx(-1,1) end
  charge=0
 end
 if fire_pending and fire_cooldown==0 and #shots<10 then
  local charged=fire_pending==3
  add(shots,{z=0,a=angle,power=fire_pending})
  sfx(charged and 1 or 4,blasting and not charged and 2 or 1)
  fire_cooldown=11 fire_flash=charged and 7 or 3 fire_pending=nil
 end
 for shot in all(shots) do
  local old_z=shot.z-speed
  shot.z=old_z+(shot.power==3 and 3.5 or 3.1)
  local wall=1000
  for g in all(gates) do
   if g.z>0 and g.z>=old_z and g.z<=shot.z and (gate_blocks(g,shot.a) or (shot.power==3 and
    (gate_blocks(g,shot.a-0.035) or gate_blocks(g,shot.a+0.035)))) then wall=min(wall,g.z) end
  end
  local victim=shot_victim(shot,old_z,wall)
  while victim do
   damage_target(victim,shot.a,shot.power)
   if shot.power!=3 then del(shots,shot) break end
   shot.hit=shot.hit or {} shot.hit[victim]=true
   victim=shot_victim(shot,old_z,wall)
  end
  if not victim then
   if wall<1000 then
    combat_effect(wall,shot.a,false) del(shots,shot)
   elseif shot.z>65 then del(shots,shot) end
  end
 end
 for e in all(enemies) do if e.dead then del(enemies,e) end end
 hazard_collisions()
end

function combat_effect(z,a,burst)
 if #combat_fx<12 then
  add(combat_fx,{z=z,a=a,age=0,life=burst and 28 or 9,burst=burst})
 end
end

function combat_point(z,a)
 local x,y,r,o,h=ring(max(0,z))
 return point_on_ring(x,y,r*0.84,a,o,h)
end

function draw_target(e)
 local x,y=combat_point(e.z,e.a)
 local a=0.75+e.a-camera_angle
 local rx,ry=cos(a),sin(a)
 local tx,ty=-ry,rx
 local size=min(150/(e.z+10),6)
 if e.kind=="gunship" then size*=1.3 end
 local bank=(e.bank or 0)*size*0.45
 local nx,ny=x-rx*size,y-ry*size
 local lx,ly=x+tx*size+rx*bank,y+ty*size+ry*bank
 local bx,by=x-tx*size-rx*bank,y-ty*size-ry*bank
 if e.kind=="bomber" or e.kind=="gunship" then
  local ex,ey=x+rx*size*0.6,y+ry*size*0.6
  local col=e.pods and 13 or 4
  local rim=e.pods and 14 or 10
  fill_triangle(nx,ny,lx,ly,bx,by,e.hit>0 and 7 or col)
  fill_triangle(ex,ey,lx,ly,bx,by,col)
  line(nx,ny,lx,ly,rim) line(nx,ny,bx,by,rim)
  line(ex,ey,lx,ly,rim) line(ex,ey,bx,by,rim)
  for i=1,2 do
   local px,py=combat_point(e.z,e.a+(i==1 and -0.065 or 0.065))
   local alive=not e.pods or e.pods[i]>0
   circfill(px,py,max(2,size*0.65),alive and (e.pods and 12 or 9) or 5)
   if alive then pset(px,py,7) end
  end
  if e.payload and e.bomb_clock<8 then circ(x,y,size+1,7) end
  return
 end
 local rim=e.kind=="fighter" and 11 or 14
 fill_triangle(nx,ny,lx,ly,bx,by,e.hit>0 and 7 or (rim==11 and 3 or 2))
 line(nx,ny,lx,ly,rim) line(nx,ny,bx,by,rim)
 line(lx,ly,x,y,8) line(bx,by,x,y,8)
 local flame=1+size*0.6
 line(x,y,x+rx*flame,y+ry*flame,9)
end

function draw_combat_band(near,far)
 for e in all(enemies) do
  if (e.state!="enter" or e.age>0) and e.z>near and e.z<=far then draw_target(e) end
 end
 draw_hazards(near,far)
 for shot in all(shots) do
  if shot.z>near and shot.z<=far then
   local charged=shot.power==3
   local x,y=combat_point(shot.z,shot.a)
   local bx,by=combat_point(max(0,shot.z-(charged and 7 or 3)),shot.a)
   local a=0.75+shot.a-camera_angle
   local _,_,radius=ring(shot.z)
   local _,_,tail_radius=ring(max(0,shot.z-7))
   local beam=max(0,flr(min(radius,tail_radius)*0.13-0.75))
   local offset=charged and beam or max(0.5,30/(shot.z+10))
   for side=-1,1,2 do
    local dx,dy=-sin(a)*offset*side,cos(a)*offset*side
    line(bx+dx,by+dy,x+dx,y+dy,charged and 10 or 12)
    pset(x+dx,y+dy,7)
   end
   if charged then
    local glow=max(0,beam-1)
    circfill(x,y,beam,9) circfill(x,y,glow,10)
    line(bx,by,x,y,7) circfill(x,y,glow/2,7)
   end
  end
 end
 for fx in all(combat_fx) do
  if fx.z>near and fx.z<=far then
   local x,y=combat_point(fx.z,fx.a)
   local radius=fx.burst and min(7,fx.age*0.4+1) or 2
   local col=fx.age<5 and 7 or (fx.burst and 9 or 5)
   for i=0,5 do
    local a=i/6+fx.age/80
    line(x+cos(a)*radius,y+sin(a)*radius,
     x+cos(a)*(radius+2),y+sin(a)*(radius+2),col)
   end
  end
 end
end

function draw_combat_hud()
 local e=enemies[1]
 if e then
  print(e.kind,3,12,14)
  local hp=e.kind=="formation" and 3-e.group.kills or e.hp
  for i=1,e.kind=="formation" and 3 or e.max_hp do
   rectfill(88+i*3,12,89+i*3,14,i<=hp and 8 or 1)
  end
 end
end

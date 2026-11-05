pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- hyperdeath murder tube
-- screaming down the death hole
-- steering values are turns per frame

function _init()
 for i=1,3 do menuitem(i) end
 max_speed=1.8518519 -- about 2000 km/h
 cartdata("marc_conduit_20261031_v1")
 best=max(0,flr(dget(0)))
 best_hi=max(0,flr(dget(1)))
 -- Shared rendering/generation; sections are just small profiles.
 zones={
  {face=2,rim=8,wall=13,ribs=0,oval=0,hex=0,
   mix={1.6,0.7,0.7,1}},
  {face=4,rim=9,wall=5,ribs=-1,oval=0,hex=1,
   mix={0.7,1.3,1.5,1}},
  {face=1,rim=12,wall=13,ribs=3,oval=1,hex=0,
   mix={2,0.45,0.4,0.8}}
 }
 reset_run()
 mode="title"
 music(0)
end


function reset_run()
 music(-1)
 sfx(-1)
 angle=0
 velocity=0
 camera_angle=0
 camera_cos=1
 camera_sin=0
 shape_oval=0
 shape_hex=0
 tunnel_width=1
 visible_width=1
 distance=0
 speed=0
 score=0
 points=0
 points_hi=0
 new_record=false
 shots={}
 combat_fx={}
 enemies={}
 mines={}
 hostile_bolts={}
 attack_gap=0
 enemy_wait=180
 kills=0
 fire_down=false
 fire_pending=nil
 charge=0
 fire_cooldown=0
 fire_flash=0
 retry_armed=false
 impact=nil
 impact_type=nil
 impact_age=0
 trail={}
 engine_note=-1
 engine_turn=0
 ticks=0
 gates={}
 generated=0
 next_rib=7
 hard_sections=0
 introduced_shutters=1
 route_zone=1
 visible_zone=1
 section_end=14
 next_gap=0
 route_anchor=0
 last_pattern=0
 choose_route()
 for i=1,6 do
  add_gate(18+i*17)
 end
 -- Plan the opening at cruising speed, then begin the launch at rest.
 speed=0
end


function turn_delta(a,b)
 return (a-b+0.5)%1-0.5
end


function crash_player(g,kind)
 mode="dead" retry_armed=false impact_age=0 impact=g impact_type=kind
 if g then
  impact_side=turn_delta(angle,g.a)>=0 and 1 or -1
 end
 local x,y,r,o,h=ring(g and g.z or 0)
 impact_x,impact_y=point_on_ring(x,y,r*0.84,angle,o,h)
 sfx(-1)
 for channel=0,3 do sfx(9+channel,channel) end
end


-- Split scores into chunks to avoid PICO-8's 32767 integer ceiling.
function score_text(hi,lo)
 local s=tostr(lo)
 if hi==0 then return s end
 while #s<4 do s="0"..s end
 return tostr(hi)..s
end

function award_points(amount)
 points+=amount
 if points>=10000 then points-=10000 points_hi+=1 end
 if points_hi>best_hi or (points_hi==best_hi and points>best) then
  best_hi,best=points_hi,points
  new_record=true
  dset(0,best)
  dset(1,best_hi)
 end
end


function clearance_at(g,a)
 local d=abs(turn_delta(a,g.a))
 local margin=0.025/tunnel_width
 if g.rib then return d-g.rib_width-margin end
 return g.width-margin-d
end


function difficulty_stage(n)
 if n<10 then return 1 end
 if n<26 then return 2 end
 if n<48 then return 3 end
 return 4
end

-- One continuous engine channel responds to speed and banking.
function update_audio()
 engine_turn+=(min(1,abs(velocity)/0.0038)-engine_turn)*0.12
 local power=mid(0,(speed-0.29)/(max_speed+0.04-0.29),1)
 local pitch=14+flr(power*22+engine_turn*3)
 local volume=engine_turn>0.55 and 3 or 2
 local note=pitch+384+volume*512
 if note!=engine_note then
  for n=0,7 do poke2(0x3200+n*2,note) end
  poke(0x3200+65,8)
  if engine_note<0 then sfx(0,0) end
  engine_note=note
 end
end


function choose_route()
 -- Switch only between complete manoeuvres, never mid-pattern.
 if generated>=section_end then
  route_zone=route_zone%#zones+1
  section_end=generated+11+flr(rnd(7))
 end
 local profile=zones[route_zone]
 -- Difficulty follows course progress, not time spent on the title.
 -- New weights apply only to newly generated sections.
 route_stage=difficulty_stage(generated)
 local difficulty=min(2,(route_stage-1)/3+max(0,generated-48)*0.003)
 local kind=1
 if last_pattern>0 then
  if hard_sections>=(route_stage==4 and 3 or 2) then
   kind=4
  elseif route_stage>introduced_shutters then
   kind=6
  else
   local weights={6.9-3.45*difficulty,1+3*difficulty,
    0.5+3.5*difficulty,2,
    route_stage>=2 and (0.6+1.8*difficulty) or 0,
    route_stage>=2 and (0.5+2.5*difficulty) or 0}
   for i=1,4 do weights[i]*=profile.mix[i] end
   if route_zone==2 then weights[5]*=1.5 weights[6]*=1.4 end
   weights[6]*=1+3*difficulty
   if last_pattern!=1 then weights[last_pattern]=0 end
   local total=0
   for w in all(weights) do total+=w end
   local pick=rnd(total)
   for i=1,6 do
    pick-=weights[i]
    if pick<0 then kind=i break end
   end
  end
 end
 if kind==2 or kind==3 or kind==5 or kind==6 then
  hard_sections+=1
 else
  hard_sections=0
 end
 route_kind=kind
 route_steps={0}
 if generated==0 then add(route_steps,0) end
 route_index=1
 local direction=kind==1 and last_pattern==1 and -route_direction or (rnd(1)<0.5 and -1 or 1)
 route_direction=direction
 last_pattern=kind
 route_width=1
 if generated>0 then
  local widths={1.06,1,0.94,0.88,0.82}
  route_width=widths[1+flr(rnd(route_stage+1))]
  if kind==4 then route_width=1.10 end
  if kind==6 then route_width=route_stage==2 and 1 or (route_stage==3 and 0.90 or 0.84) end
 end
 local length=3+flr(rnd(4))
 if route_zone==3 then length+=2 end
 local strength=0.085+0.025*difficulty+rnd(0.02)
 if kind==1 then
  -- long spiral: build, hold, release
  add_sweep(direction,strength,length+3)
 elseif kind==2 then
  -- gentle weave: two or three rounded alternating turns
  for i=1,2+flr(rnd(2)) do
   add_sweep(direction,0.06+0.015*difficulty+rnd(0.015),1)
   direction=-direction
  end
 elseif kind==3 then
  -- Two or three reversals, easing briefly before each change.
  for i=1,3+flr(rnd(2)) do
   add_sweep(direction,strength,1)
   direction=-direction
  end
 elseif kind==4 then
  -- recover through a gentle moving bend, not a long static straight
  add_sweep(direction,0.065+0.015*difficulty,1)
 elseif kind==5 then
  -- two offset ribs, then a gate; mirrored as a whole.
  -- Wider spacing allows a weave or a continuous outside sweep.
  route_steps={0,0.04,0.12,0.12,0.06,0.02,0}
  for i=1,#route_steps do route_steps[i]*=direction end
 else
  introduced_shutters=route_stage
  if route_stage==2 then
   route_steps={0,0.08,0.08,0.04,0}
  elseif route_stage==3 then
   route_steps={0,0.04,0.08,0.08,0.08,0.04,0}
  else
   route_steps={0,0.04,0.12,0.12,0.08,0.08,0.04,0}
  end
  for i=1,#route_steps do route_steps[i]*=direction end
 end
 -- A second shutter always has ordinary guide gates on both sides.
 route_extra_shutter=rnd(1)<min(0.92,0.65*difficulty)
end


function add_sweep(direction,strength,length)
 add(route_steps,direction*strength*0.45)
 add(route_steps,direction*strength*0.8)
 for i=1,length do add(route_steps,direction*strength) end
 add(route_steps,direction*strength*0.8)
 add(route_steps,direction*strength*0.45)
 add(route_steps,0)
end

-- Bound the possible shutter angle at arrival, across the speed range.

function crossing_offsets(g,slow,fast)
 if not g.clocked then return 0,0 end
 local duration=g.roll_duration or 150
 local early=min(1,45/fast/duration)
 local late=min(1,45/slow/duration)
 local a=g.roll_start+g.turn*early*early
 local b=g.roll_start+g.turn*late*late
 return min(a,b),max(a,b)
end


function protect_transition(previous,g,step)
 if not previous then return end
 local slow=max(0.32,speed)
 local fast=min(max_speed,speed+0.015)+0.04
 -- Test complete ordinary openings and both intended sides of ribs.
 local margin=0.025/0.82
 local p_half=previous.rib and 0.16 or previous.width-margin
 local n_half=g.width-margin-0.008
 local p_lo,p_hi=crossing_offsets(previous,slow,fast)
 local n_lo,n_hi=crossing_offsets(g,slow,fast)
 local delta=turn_delta(g.base_a,previous.base_a)
 local needed=max(0,max(delta+n_hi-p_lo,-delta+p_hi-n_lo)+p_half-n_half)
 if g.rib then needed=g.rib_width+margin+0.015 end
 local special=previous.rib or g.rib or previous.clocked or g.clocked
  or previous.pattern!=route_kind or previous.step*step<0
 -- Extra time includes braking from an outward edge exit.
 local reserve=special and 34 or 10
 local spacing=max(previous.gap,(needed/0.0036+reserve)*fast)
 g.z=max(g.z,previous.z+spacing)
end


function add_gate(z)
 -- preserve the last opening angle when joining manoeuvres
 local step=route_steps[route_index]
 if route_kind<=4 then
  -- Leave steering headroom at the conservative approach speed.
  -- Authored combinations already have their own wider spacing.
  local limit=0.00345*17/(min(max_speed,speed+0.015)+0.04)
  step=mid(-limit,step,limit)
 end
 next_gap=(next_gap+step)%1
 generated+=1
 -- Gradually increase ribs from one in eight to at most one in five.
 -- Recovery bends remain gates only; overdue ribs wait for a new section.
 local rib=generated>=next_rib and route_kind!=4
 if route_kind==5 then rib=route_index==2 or route_index==3 end
 local timed=false
 if route_kind==6 then
  rib=(route_stage>=3 and route_index==2) or (route_stage==4 and route_index==3)
  timed=route_index==(route_stage==2 and 2 or (route_stage==3 and 4 or 5))
   or (route_extra_shutter and route_index==#route_steps-1)
 end
 if rib then
  local spacing=8
  if generated>=30 then spacing=6 end
  if generated>=65 then spacing=5 end
  spacing=max(4,spacing+zones[route_zone].ribs)
  next_rib=generated+spacing
 end
 local turn=timed and -route_direction*0.25 or 0
 local start=-turn/2
 local gap=route_kind==5 and 24 or 17
 if route_kind==6 then gap=route_stage==2 and 32 or (route_stage==3 and 28 or 26) end
 local duration=route_stage==4 and 120 or (route_stage==3 and 135 or 150)
 duration=max(60,duration*min(1,0.42/max(0.42,speed)))
 local g={z=z,a=(next_gap+start)%1,
  base_a=next_gap,turn=turn,width=timed and (0.20-route_stage*0.01) or 0.19,
  rib=rib,rib_width=0.055,zone=route_zone,
  gap=gap,radius=route_width,
  clocked=timed,roll_age=0,roll_start=start,
  roll_duration=duration,pattern=route_kind,step=step}
 protect_transition(gates[#gates],g,step)
 add(gates,g)
 route_index+=1
 if route_index>#route_steps then
  choose_route()
 end
end


function _update60()
 ticks=(ticks+1)%240
 if mode!="play" then
  if mode=="title" then distance=(distance+0.12)%13120 end
  if mode=="dead" then impact_age=min(90,impact_age+1)
   if impact_age==89 then music(0) end end
  local ready=mode=="title" or impact_age>=45
  if not ready then retry_armed=false end
  if ready and not btn(4) and not btn(5) then retry_armed=true end
  if ready and (mode=="title" or retry_armed) and (btnp(4) or btnp(5)) then
   reset_run()
   mode="play" fire_down=btn(4) or btn(5)
  end
  return
 end
 local steer=0
 if btn(0) then steer-=1 end
 if btn(1) then steer+=1 end
 velocity=velocity*0.78+steer*0.00102
 angle=(angle+velocity)%1
 camera_angle=(camera_angle+turn_delta(angle,camera_angle)*0.16)%1
 camera_cos=cos(-camera_angle)
 camera_sin=sin(-camera_angle)
 local profile=zones[visible_zone]
 shape_oval+=(profile.oval-shape_oval)*0.035
 shape_hex+=(profile.hex-shape_hex)*0.035
 tunnel_width+=(visible_width-tunnel_width)*0.035
 -- Launch from 0 to 1000 km/h, then add about 5 km/h per second.
 if speed<0.9259259 then speed=min(0.9259259,speed+0x0.0155)
 else speed=min(max_speed,speed+0x0.0005) end
 distance=(distance+speed)%13120
 update_audio()
 add(trail,angle)
 if #trail>9 then deli(trail,1) end
 for g in all(gates) do
  local old_z=g.z
  g.previous_z=old_z
  g.z-=speed
  if g.clocked then
   -- Timed shutters run on elapsed frames once within 45 units.
   -- A bounded, accelerating sweep makes an earlier interception matter.
   local duration=g.roll_duration or 150
   if old_z>0 and g.z<=45 then g.roll_age=min(duration,g.roll_age+1) end
   local progress=g.roll_age/duration
   g.a=(g.base_a+g.roll_start+g.turn*progress*progress)%1
  else
   -- Normal-run shutters retain their established distance-based motion.
   g.a=(g.base_a+g.turn*mid(0,g.z/65,1))%1
  end
  -- the ship occupies the ring at z=0
  if old_z>0 and g.z<=0 then
   local clearance=clearance_at(g,angle)
   if clearance<0 then
    crash_player(g,"gate")
    return
   else
    route_anchor=g.rib and (g.a+0.13)%1 or g.a
    score+=1
    award_points(100)
   end
  end
 end
 if gates[1].z < -4 then
  del(gates,gates[1])
  local last=gates[#gates]
  add_gate(last.z+last.gap)
 end
 -- Match the nearby tunnel colour to the next obstacle.
 for g in all(gates) do
  if g.z>0 then
   if g.zone!=visible_zone then
    visible_zone=g.zone
   end
   visible_width=g.radius or 1
   break
  end
 end
 update_combat()
end

-- perspective ring. distant rings gently bend away.

function shape_at(z)
 local prev_z=0
 local o,h,w=shape_oval,shape_hex,tunnel_width
 for g in all(gates) do
  if g.z>0 then
   local profile=zones[g.zone]
   if z<=g.z then
    local t=mid(0,(z-prev_z)/(g.z-prev_z),1)
    t=t*t*(3-2*t)
    return o+(profile.oval-o)*t,h+(profile.hex-h)*t,
     w+((g.radius or 1)-w)*t
   end
   prev_z=g.z
   o,h=profile.oval,profile.hex
   w=g.radius or 1
  end
 end
 return o,h,w
end


function ring(z)
 local r=680/(z+10)
 local bend=z/(z+24)
 local x=64+sin(distance/320+z/220)*15*bend
 local y=56+sin(distance/410+z/270)*10*bend
 local o,h,w=shape_at(max(0,z))
 return x,y,r*w,o,h
end


function point_on_ring(x,y,r,a,o,h)
 local t=0.75+a
 if o<0.001 and h<0.001 then
  t-=camera_angle
  return x+cos(t)*r,y+sin(t)*r
 end
 local scale=1
 if h>0.001 then
  local sector=(t+1/12)%(1/6)-1/12
  scale+=h*(0.8660254/cos(sector)-1)
 end
 local ux=cos(t)*r*scale*(1+0.12*o)
 local uy=sin(t)*r*scale*(1-0.20*o)
 return x+ux*camera_cos-uy*camera_sin,
  y+uy*camera_cos+ux*camera_sin
end


function draw_ring(z,col)
 local x,y,r,o,h=ring(z)
 local px,py=point_on_ring(x,y,r,0,o,h)
 for i=1,24 do
  local nx,ny=point_on_ring(x,y,r,i/24,o,h)
  line(px,py,nx,ny,col)
  px,py=nx,ny
 end
end

-- Scanline triangles make opaque panels without sprites or dithering.

function fill_triangle(x1,y1,x2,y2,x3,y3,col)
 if y1>y2 then x1,x2=x2,x1 y1,y2=y2,y1 end
 if y2>y3 then x2,x3=x3,x2 y2,y3=y3,y2 end
 if y1>y2 then x1,x2=x2,x1 y1,y2=y2,y1 end
 if y3-y1<0.001 then return end
 for y=max(0,flr(y1)),min(127,flr(y3)) do
  local sample=y+0.5
  if sample>=y1 and sample<y3 then
   local a=x1+(x3-x1)*(sample-y1)/(y3-y1)
   local b=a
   if sample<y2 then
    if y2>y1 then b=x1+(x2-x1)*(sample-y1)/(y2-y1) end
   else
    if y3>y2 then b=x2+(x3-x2)*(sample-y2)/(y3-y2) end
   end
   local left=-flr(-(min(a,b)-0.5))
   local right=flr(max(a,b)-0.5)
   if left<=right then line(left,y,right,y,col) end
  end
 end
end


function draw_gate(g,active)
 -- distant gates are silhouettes, not a stack of bright edges
 if g.z>65 then return end
 local x,y,r,o,h=ring(max(g.z,-3))
 local profile=zones[g.zone]
 local moving=g.turn!=0
 local body,edge=1,2
 if g.z<42 then body,edge=profile.face,9 end
 if active and g.z<42 then body,edge=profile.rim,10 end
 if moving and g.z<55 then edge=g.z<42 and 8 or 6 end
 local rib=g.rib
 local inner=rib and 0.42 or 0.40
 local boundary=rib and g.rib_width or g.width
 if rib and g.z<42 then body=active and 9 or 4 end
 local face=1
 if g.z<42 then face=moving and 10 or (rib and 4 or profile.face) end
 -- 32 solid panels, clipped exactly at the opening boundaries.
 for i=0,31 do
  local d=turn_delta((i+0.5)/32,g.a)
  local lo,hi=d-1/64,d+1/64
  if rib then
   lo=max(lo,-boundary) hi=min(hi,boundary)
  elseif d>=0 then
   lo=max(lo,boundary)
  else
   hi=min(hi,-boundary)
  end
  if lo<hi then
   local x1,y1=point_on_ring(x,y,r,g.a+lo,o,h)
   local x2,y2=point_on_ring(x,y,r,g.a+hi,o,h)
   local x3,y3=x+(x1-x)*inner,y+(y1-y)*inner
   local x4,y4=x+(x2-x)*inner,y+(y2-y)*inner
   fill_triangle(x1,y1,x2,y2,x3,y3,face)
   fill_triangle(x2,y2,x4,y4,x3,y3,face)
   line(x1,y1,x2,y2,body)
   line(x3,y3,x4,y4,body)
  end
 end
 -- gate edges frame an opening; rib edges frame a solid orange wedge
 for side=-1,1,2 do
  local a=g.a+side*boundary
  local x1,y1=point_on_ring(x,y,r,a,o,h)
  local x2,y2=x+(x1-x)*(inner-0.03),y+(y1-y)*(inner-0.03)
  line(x1,y1,x2,y2,edge)
  if moving and g.z<55 then
   local bx,by=point_on_ring(x,y,r,a+side*0.012,o,h)
   local cx,cy=x+(bx-x)*(inner-0.03),y+(by-y)*(inner-0.03)
   fill_triangle(x1,y1,bx,by,x2,y2,edge)
   fill_triangle(bx,by,cx,cy,x2,y2,edge)
   for n=1,2 do
    local mark=a+side*n*0.065
    local px,py=point_on_ring(x,y,r*0.54,mark,o,h)
    local qx,qy=point_on_ring(x,y,r*0.70,mark-side*0.025,o,h)
    local sx,sy=point_on_ring(x,y,r*0.86,mark,o,h)
    line(px,py,qx,qy,0) line(qx,qy,sx,sy,0)
   end
  end
 end
end


function draw_ship()
 local a=0.75+angle-camera_angle
 local rx,ry=cos(a),sin(a)
 local tx,ty=-ry,rx
 local x,y=point_on_ring(64,56,57*tunnel_width,angle,shape_oval,shape_hex)
 local bank=velocity*650
 -- engine trails retain recent steering, staying behind the ship
 if mode=="play" then
  for side=-1,1,2 do
   local px,py=x+tx*side*3,y+ty*side*3
   for age=1,#trail do
    local ta=0.75+trail[#trail-age+1]-camera_angle
    local tr=57+age*1.3
    local nx,ny=point_on_ring(64,56,tr*tunnel_width,
     trail[#trail-age+1],shape_oval,shape_hex)
    nx-=sin(ta)*side*3
    ny+=cos(ta)*side*3
    line(px,py,nx,ny,age<4 and 12 or 1)
    px,py=nx,ny
   end
  end
 end
 local flare=mode=="play" and abs(velocity)*1200 or 0
 local flame=4+(ticks%4)+flare+max(0,speed-0.29)*16
 line(x+tx*3,y+ty*3,x+tx*3+rx*flame,y+ty*3+ry*flame,9)
 line(x-tx*3,y-ty*3,x-tx*3+rx*flame,y-ty*3+ry*flame,9)
 -- Inverse-map a 16x16 sprite so rotation has no pixel holes.
 -- Shearing along the wings preserves the established banking motion.
 for py=max(0,flr(y-13)),min(127,flr(y+13)) do
  for px=max(0,flr(x-13)),min(127,flr(x+13)) do
   local dx,dy=px-x,py-y
   local u=dx*tx+dy*ty
   local v=dx*rx+dy*ry-u*bank/7
   local sx,sy=flr(u+8),flr(v+9)
   if sx>=0 and sx<16 and sy>=0 and sy<16 then
    local c=sget(sx,sy)
    if c!=0 then pset(px,py,c) end
   end
  end
 end
 if mode=="play" and abs(velocity)>0.002 then
  -- PICO-8's sine direction makes positive rotation move against
  -- our wing tangent: exhaust must point along that tangent.
  local side=velocity>0 and 1 or -1
  line(x+tx*side*6,y+ty*side*6,
   x+tx*side*10+rx*2,y+ty*side*10+ry*2,10)
 end
 if fire_flash>3 then circfill(x-rx*8,y-ry*8,fire_flash,7) end
 if fire_flash>0 and mode=="play" then
  for side=-1,1,2 do
   local mx,my=x-rx*6+tx*side*3,y-ry*6+ty*side*3
   line(mx,my,mx-rx*3,my-ry*3,7)
  end
 end
end


function draw_streaks()
 -- just six wall streaks, drawn behind gates in a muted colour
 for i=0,5 do
  local z=5+(i*11-distance*1.7)%62
  local a=i/6+0.07
  local x,y,r,o,h=ring(z)
  local x2,y2,r2,o2,h2=ring(z+2+max(0,speed-0.29)*16)
  local px,py=point_on_ring(x,y,r,a,o,h)
  local qx,qy=point_on_ring(x2,y2,r2,a,o2,h2)
  line(px,py,qx,qy,z<22 and 5 or 1)
 end
end


function draw_impact()
 if not impact and not impact_type then return end
 -- The closest boundary stays highlighted after the short burst.
 if impact then
 local x,y,r,o,h=ring(impact.z)
 local rib=impact.rib
 local boundary=rib and impact.rib_width or impact.width
 local a=impact.a+impact_side*boundary
 local x1,y1=point_on_ring(x,y,r,a,o,h)
 local x2,y2=point_on_ring(x,y,r*(rib and 0.42 or 0.40),a,o,h)
 line(x1,y1,x2,y2,7)
 end
 circ(impact_x,impact_y,3,10)
 if impact_age<2 then cls(7) end
 if impact_age<40 then
  circ(impact_x,impact_y,impact_age*2,impact_age<12 and 10 or 5)
  if impact_age<22 then
   circfill(impact_x,impact_y,12-impact_age*0.5,impact_age<6 and 7 or 9)
  end
  for i=0,15 do
   local t=i/16+impact_age*0.002
   local spread=impact_age*(0.8+(i%5)*0.3)
   local px=impact_x+cos(t)*spread
   local py=impact_y+sin(t)*spread
   line(px,py,px+cos(t)*7,py+sin(t)*7,
    impact_age<6 and 7 or (impact_age<16 and 10 or (impact_age<28 and 9 or 5)))
  end
 end
end


function centered(s,y,c)
 print(s,64-#s*2,y,c)
end


function _draw()
 cls(0)
 if mode=="dead" and impact_age<14 then
  local kick=(14-impact_age)*0.3
  camera(sin(impact_age*0.31)*kick,cos(impact_age*0.37)*kick)
 end
 -- longitudinal seams connect the rolling rings
 for j=0,5 do
  local px,py
  for k=6,0,-1 do
   local z=k*10
   local x,y,r,o,h=ring(z)
   local nx,ny=point_on_ring(x,y,r,j/6,o,h)
   if px then line(px,py,nx,ny,1) end
   px,py=nx,ny
  end
 end
 for i=6,0,-1 do
  local z=i*10+10-distance%10
  draw_ring(z,z<24 and zones[visible_zone].wall or 1)
 end
 if mode=="play" then draw_streaks() end
 local nearest=0
 for i=1,#gates do
  if gates[i].z>0 then nearest=i break end
 end
 local far=1000
 for i=#gates,1,-1 do
  draw_combat_band(gates[i].z,far)
  if gates[i].z>-4 then draw_gate(gates[i],i==nearest) end
  far=gates[i].z
 end
 draw_combat_band(-4,far)
 if mode!="dead" then draw_ship() end
 if mode=="dead" then draw_impact() end
 camera()
 rectfill(0,0,127,9,0)
 if mode!="title" then
  print("pts "..score_text(points_hi,points),3,2,7)
  local best_label="best "..score_text(best_hi,best)
  print(best_label,125-#best_label*4,2,6)
 end
 if mode=="play" then draw_combat_hud() end
 if mode=="title" then
  rectfill(8,20,119,108,0)
  line(18,24,109,24,12)
  print("\^w\^thyperdeath\^-w\^-t",24,29,12)
  print("\^w\^tmurder tube\^-w\^-t",20,41,12)
  centered("screaming down the death hole",54,6)
  centered("best "..score_text(best_hi,best),64,10)
  centered("\139 / \145 to bank",73,6)
  centered("tap \142 or \151 to fire",82,6)
  centered("hold to charge shot",90,6)
  centered("press \142 / \151",99,ticks%60<30 and 11 or 5)
 elseif mode=="dead" then
  if impact_age>=20 then
  rectfill(10,20,117,109,0)
  centered((impact_type=="mine" or impact_type=="bolt") and "hull breach!" or "wrecked!",26,10)
  centered("ship destroyed!",34,7)
  if new_record then centered("new high score!!!",44,ticks%40<20 and 10 or 7) end
  centered("score "..score_text(points_hi,points),58,7)
  centered("best "..score_text(best_hi,best),66,6)
  centered("max speed "..flr(speed*1080+0.5).."km/h",78,12)
  centered("gates "..score.." kills "..kills,90,6)
  centered(impact_age>=45 and "\142 / \151 to retry" or "...",102,
   impact_age>=45 and 11 or 5)
  end
 else
  print(flr(speed*1080+0.5).."km/h",3,113,5)
  if charge>0 then
   rect(86,113,123,117,5)
   rectfill(87,114,87+flr(charge*0.6),116,charge==60 and 10 or 12)
  end
  centered("gates "..score,121,6)
 end
 if mode=="play" and speed<0.9259259 and ticks%20<12 then
  print("\^w\^tgo!!!\^-w\^-t",44,52,10)
 end
 if mode=="dead" and impact_age<5 then
  rect(0,10,127,127,8)
 end
end

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

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000007cc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c77c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000c1cc7c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c117711c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c117611c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c11176111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c1111761111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c1111771111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c116900009611c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c16710000176cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc671000000176cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c77100000000177c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000400080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001e6710e6001e6710e60022661206511e6511c6511b6411a641196411864117641166411564114641136411264111641106410f6410e6410d6410c7310b7310a731097310873107731067250572504705
000400001e6601b6501864015630126200f6100c60009600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000347412a741207311872112715107000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000236301f6201b6101760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000019650176501564013640116300f6300d6200b620096100761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001471115711167111771118711197111a7111b7211c7211d7211e7211f721207212172122721237212472125721267212772128721297212a7212b7210000000000000000000000000000000000000000
000600081202112021130211302112021120211102111021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000034663306602c6602865024650206501c6401864014640106300c630086300462003620036200361000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000170511505113051110510f0510d0410b04109041070410504103031010310003100031000310002100021000210002100021000110001100011000110000000000000000000000000000000000000000
000300003674133741307412d7412a7312773124731217311e7211b7211872115721127110f7110c7110971100000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000000036633000002f6330000000000286230000000000216230000000000000001a613000000000000000000001361300000000000000000000000000000000000000000000000000000000000000000
002000200003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030
002000201201112011120111201112011120111201112011130111301113011130111301113011130111301112011120111201112011120111201112011120111101111011110111101112011120111201112011
002000202a0012a0012a0012a0012a0012a0012a0012a0012b0142b0112b0112b0112b0112b0112b0112b0112c0112c0112c0112c0112c0112c0112c0112c0152d0012d0012d0012d0012d0012d0012d0012d001
002000200630006300063000630006300063000630006300063000630006300063000630006300063000630006314063100631006310063100631006310063100631006310063100631006310063100631006315

__music__
03 0d0e0f10

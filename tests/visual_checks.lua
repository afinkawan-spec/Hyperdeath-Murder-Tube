_init()
btn=function(n) return false end
btnp=function(n) return false end
assert(sget(7,1)==7 and sget(7,4)==12,"native dart pixels loaded")
-- The scenery phase wraps on whole bend periods, avoiding a long-run jump.
distance=13120-0.1
local sx,sy=ring(40)
distance=0
local ex,ey=ring(40)
assert(abs(sx-ex)<0.05 and abs(sy-ey)<0.05,"long-run tunnel bend remains continuous at wrap")
-- Check shutter motion and collision against the same planned crossing.
for direction in all({-1,1}) do
 reset_run() mode="play" speed=max_speed
 for i=1,#gates do gates[i].z=65+(i-1)*17 end
 local g=gates[1]
 g.base_a=0.1 g.turn=direction*0.045 g.a=(g.base_a+g.turn)%1
 local before=abs(turn_delta(g.a,g.base_a))
 _update60()
 assert(abs(turn_delta(g.a,g.base_a))<before,"shutter rotates on approach")
 g.z=0.1 angle=g.base_a
 _update60()
 assert(mode=="play" and score==1,"shutter crossing reachable")
 assert(abs(turn_delta(g.a,g.base_a))<0.001,"shutter settles on route")
end
-- Draw and capture each shape with a banked ship and nearby obstacles.
local steering=0
btn=function(n)
 if n==0 then return steering<0 end
 if n==1 then return steering>0 end
 return false
end
for direction in all({-1,1}) do
 for variant=0,0 do
  reset_run() mode="play" speed=max_speed
  for i=1,#gates do gates[i].z=65+(i-1)*17 end
  local g=gates[1]
  g.base_a=0.20 g.turn=direction*0.045
  g.a=(g.base_a+g.turn)%1
  for frame=1,170 do
   local error=turn_delta(g.a,angle)-velocity*5
   steering=abs(error)<0.001 and 0 or (error>0 and 1 or -1)
   
   _update60()
   assert(mode=="play","steering can intercept shutter")
   if score>0 then break end
  end
  assert(score==1,"shutter reached at full speed")
 end
end
btn=function(n) return false end
for zone=1,3 do
 reset_run() mode="play" speed=0.5555556
 visible_zone=zone
 shape_oval=zones[zone].oval shape_hex=zones[zone].hex
 camera_angle=0.07 camera_cos=cos(-camera_angle) camera_sin=sin(-camera_angle)
 angle=0.1 velocity=0.003
 for i=1,#gates do
  local g=gates[i]
  g.zone=zone g.z=6+(i-1)*19
  g.base_a=0.1+i*0.08 g.a=g.base_a
  g.turn=0 g.rib=i==2
 end
 gates[1].turn=0.045
 for z=0,120,5 do
  local o,h=shape_at(z)
  assert(o>=0 and h>=0 and o+h<1.001,"shape blend stays bounded")
 end
 local before=stat(1)
 _draw()
 printh("zone "..zone.." cpu "..(stat(1)-before),"render_cost.txt",zone==1)
 extcmd("screen",3,1)
end
for zone=1,3 do
 for width in all({0.82,1,1.10}) do
 for depth in all({-3,0,6}) do
  reset_run() mode="play" speed=0.5555556 visible_zone=zone
  tunnel_width=width visible_width=width
  shape_oval=zones[zone].oval shape_hex=zones[zone].hex
  for i=1,#gates do
   gates[i].zone=zone gates[i].z=depth+(i-1)*17 gates[i].radius=width
  end
  local before=stat(1)
  _draw()
  local cost=stat(1)-before
  assert(cost<0.94,"stress draw stays within frame budget")
  printh("stress "..zone.." w "..width.." z "..depth.." cpu "..cost,"render_cost.txt")
  if zone==2 and depth==6 and width!=1 then extcmd("screen",3,1) end
 end
 end
end
printh("PASS","visual_result.txt",true)

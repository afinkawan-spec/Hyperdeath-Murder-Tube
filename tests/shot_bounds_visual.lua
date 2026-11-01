_init()
camera_angle=0.173 camera_cos=cos(-camera_angle) camera_sin=sin(-camera_angle)
local checked=0
zones[4]={oval=0.5,hex=0.5}
for zone=1,4 do
 for width in all({0.82,1,1.10}) do
  reset_run() mode="play" speed=0.8
  camera_angle=0.173 camera_cos=cos(-camera_angle) camera_sin=sin(-camera_angle)
  shape_oval=zones[zone].oval shape_hex=zones[zone].hex tunnel_width=width
  for g in all(gates) do g.zone=zone g.radius=width end
  for z in all({1,4,12,24,45,65}) do
   for direction=0,23 do
    local a=direction/24
    shots={{z=z,a=a,power=3}} cls(0) draw_combat_band(-4,1000)
    local x,y=combat_point(z,a)
    local tx,ty=combat_point(max(0,z-7),a)
    for py=max(0,flr(min(y,ty)-12)),min(127,flr(max(y,ty)+12)) do
     for px=max(0,flr(min(x,tx)-12)),min(127,flr(max(x,tx)+12)) do
      if pget(px,py)!=0 then
       local inside=false
       for step=0,7 do
        local depth=max(0,z-step)
        local cx,cy,r,o,h=ring(depth)
        local dx,dy=px-cx,py-cy
        local ux=(dx*camera_cos+dy*camera_sin)/(1+0.12*o)
        local uy=(dy*camera_cos-dx*camera_sin)/(1-0.20*o)
        local actual=(atan2(ux,uy)-0.75)%1
        if abs(turn_delta(actual,a))<=0.035 then inside=true break end
       end
       if not inside then
        printh("zone "..zone.." width "..width.." z "..z.." a "..a.." pixel "..px..","..py,"shot_bounds_failure.txt",true)
       end
       assert(inside,"charged projectile pixel stays in angular hit window")
      end
     end
    end
    checked+=1
   end
  end
 end
end
printh("PASS "..checked.." rendered cases","shot_bounds_log.txt",true)
printh("PASS","shot_bounds_visual_result.txt",true)

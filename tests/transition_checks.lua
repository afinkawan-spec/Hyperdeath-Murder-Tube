_init()
update_combat=function() end
award_points=function(amount) end
local steering=0
btn=function(n)
 if n==0 then return steering<0 end
 if n==1 then return steering>0 end
 return false
end
btnp=function(n) return false end
local count=0
for case=1,5 do
 for trial=0,0 do
  for side in all({-1,1}) do
   for phase=1,2 do
    reset_run() mode="play" speed=max_speed
    tunnel_width=0.82 visible_width=0.82
    route_kind=3
    local p={base_a=0,width=0.19,rib=case==3,gap=17,z=0,
     pattern=1,step=0.10,clocked=case==2,
     turn=-0.25,roll_start=0.125,roll_duration=100}
    local g={base_a=0.11,width=case==5 and 0.16 or 0.19,
     rib=case==4,rib_width=0.055,gap=17,z=17,
     zone=1,radius=0.82,stage=4,pattern=3,step=0.11,
     clocked=case==5,roll_age=0,roll_start=0.125,
     turn=case==5 and -0.25 or 0,roll_duration=100}
    protect_transition(p,g,g.step)
    local lo,hi=crossing_offsets(p,speed,max_speed+0.04)
    local offset=phase==1 and lo or hi
    local half=p.rib and 0.16 or p.width-0.025/tunnel_width
    angle=(offset+side*(half-0.003))%1
    velocity=side*0.00102/(1-0.78)
    camera_angle=angle
    local travel=speed
    if g.clocked then g.roll_age=max(0,flr((45-g.z)/travel)) end
    g.a=g.base_a
    gates={g}
    for i=1,5 do
     add(gates,{z=1000+i*17,a=0,base_a=0,turn=0,width=0.19,
      rib=false,rib_width=0.055,zone=1,radius=0.82,gap=17})
    end
    for frame=1,600 do
     if frame<=8 then
      steering=side
     else
      local aim=g.a
      if g.rib then
       aim=(aim+(turn_delta(angle,aim)>=0 and 0.115 or -0.115))%1
      end
      local error=turn_delta(aim,angle)-velocity*5
      steering=abs(error)<0.001 and 0 or (error>0 and 1 or -1)
     end
     
     _update60()
     if mode!="play" then
      printh("case "..case.." trial "..trial.." edge "..side..
       " phase "..phase.." clearance "..clearance_at(g,angle),
       "transition_log.txt",true)
     end
     assert(mode=="play","edge exit must permit braking and reaction")
     if score>0 then break end
    end
    assert(score==1,"next obstacle reached")
    count+=1
   end
  end
 end
end
printh("PASS: "..count.." edge-exit transitions with outward momentum, "..
 "eight reaction frames, narrow tunnel, top speed",
 "transition_log.txt",true)
printh("PASS","transition_result.txt",true)

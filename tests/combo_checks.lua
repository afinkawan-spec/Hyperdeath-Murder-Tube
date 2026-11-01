_init()
update_combat=function() end
update_hazards=function() end
hazard_collisions=function() end
drop_mines=function(g) end
award_points=function(amount) end
local steering=0
btn=function(n)
 if n==0 then return steering<0 end
 if n==1 then return steering>0 end
 return false
end
btnp=function(n) return false end
local paths={{0,0.14,0.06,0.16,0.25,0.32,0.36},
 {0,0.14,0.26,0.28,0.34,0.36,0.36}}
local cases=0
for direction in all({-1,1}) do
 for path in all(paths) do
  for width in all({0.82,1,1.10}) do
   for start_speed in all({0.5555556,max_speed}) do
    for variant=0,0 do
     reset_run() speed=start_speed
     generated=80 section_end=1000 route_zone=1
     for attempt=1,100 do
      choose_route()
      if route_kind==5 then break end
     end
     assert(route_kind==5,"select production rib-pair pattern")
     local flip=direction/(route_steps[2]>0 and 1 or -1)
     for i=1,#route_steps do route_steps[i]*=flip end
     route_direction=direction route_width=width route_index=1
     gates={} next_gap=0
     for i=1,7 do
      local last=gates[#gates]
      add_gate(last and last.z+last.gap or 35)
     end
     tunnel_width=width visible_width=width
     mode="play"
     for frame=1,2000 do
      local aim=path[score+1]*direction
      local error=turn_delta(aim,angle)-velocity*5
      steering=abs(error)<0.001 and 0 or (error>0 and 1 or -1)
      
      _update60()
      assert(mode=="play","production spacing preserves weave and sweep")
      if score==7 then break end
     end
     assert(score==7,"complete authored combination")
     cases+=1
    end
   end
  end
 end
end
printh("PASS: "..cases.." production combo paths across directions, widths, "..
 "starting/top speed","combo_log.txt",true)
printh("PASS","combo_result.txt",true)

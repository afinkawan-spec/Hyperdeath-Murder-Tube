_init()
srand(72)
local spirals,chicanes=0,0
for trial=1,300 do
 generated=80 section_end=1000 introduced_shutters=4 hard_sections=0
 last_pattern=1 route_direction=trial%2==0 and 1 or -1
 local previous=route_direction
 choose_route()
 if route_kind==1 then
  assert(route_direction==-previous,"consecutive spirals oppose each other")
  spirals+=1
 elseif route_kind==3 then
  local sign=0 local changes=0
  for step in all(route_steps) do
   local next_sign=sgn(step)
   if step!=0 then
    if sign!=0 and sign!=next_sign then changes+=1 end
    sign=next_sign
   end
  end
  assert(changes==2 or changes==3,"chicanes contain two or three reversals")
  chicanes+=1
 end
end
assert(spirals>0 and chicanes>0,"both new pattern options occur")
printh("PASS","patterns_result.txt",true)

_init()
-- Attach stage labels only in the diagnostic fixture, not the shipping gate data.
local generate=add_gate
add_gate=function(z)
 local stage=route_stage
 generate(z)
 gates[#gates].stage=stage
end
update_combat=function() end
update_hazards=function() end
hazard_collisions=function() end
drop_mines=function(g) end
local steering=0
btn=function(n)
 if n==0 then return steering<0 end
 if n==1 then return steering>0 end
 return false
end
btnp=function(n) return false end
-- Focus on generated geometry; scoring/storage have separate regression checks.
award_points=function(amount) end
local narrow,wide=1,1
local timed_counts={0,0,0,0}
for seed=1,6 do
 for trial=0,2 do
  srand(seed) reset_run()
  mode="play" speed=trial==2 and speed or (trial==1 and 0.7 or max_speed)
 
  local previous_rib=false
  local previous="start"
  for frame=1,16000 do
   local target,following
   for i=1,#gates do
    if gates[i].z>0 then target=gates[i] following=gates[i+1] break end
   end
   local aim=target.a
   if target.rib then
    if not target.side then
     local left=(target.a-0.115)%1
     local right=(target.a+0.115)%1
     local next_a=following and following.base_a or target.a
     -- Prefer the reachable near side; use the following gate as a tie-break.
     local lc=abs(turn_delta(left,angle))+abs(turn_delta(next_a,left))*0.2
     local rc=abs(turn_delta(right,angle))+abs(turn_delta(next_a,right))*0.2
     target.side=lc<rc and -1 or 1
    end
    aim=(aim+target.side*0.115)%1
   end
   local error=turn_delta(aim,angle)-velocity*5
   steering=abs(error)<0.001 and 0 or (error>0 and 1 or -1)
   
   local old_score=score
   local old_width=tunnel_width
   _update60()
   if mode!="play" then
    printh("seed "..seed.." trial "..trial.." cleared "..score..
     " stage "..target.stage.." rib "..tostr(target.rib)..
     " timed "..tostr(target.clocked).." clearance "..clearance_at(target,angle)..
     " angle "..angle.." base "..target.base_a.." side "..tostr(target.side)..
     " width "..tunnel_width.." velocity "..velocity.." previous "..previous,
     "progression_log.txt",true)
   end
   assert(mode=="play","generated route must remain reachable")
   assert(abs(tunnel_width-old_width)<0.011,"width transitions stay smooth")
   assert(tunnel_width>=0.819 and tunnel_width<=1.101,"width stays bounded")
   if frame%100==0 then
    local o,h,w=shape_at(33)
    assert(w>=0.819 and w<=1.101,"distant contour width stays bounded")
   end
   narrow=min(narrow,tunnel_width) wide=max(wide,tunnel_width)
   if score>old_score then
    if target.clocked then
     assert(target.stage>=2,"no shutters in opening stage")
     assert(not previous_rib,"guide before timed shutter")
     assert(following and not following.rib and not following.clocked,
      "guide after timed shutter")
     timed_counts[target.stage]+=1
    end
    previous_rib=target.rib
    previous="a "..angle.." base "..target.base_a.." timed "..tostr(target.clocked)
   end
   if score>=160 then break end
  end
  assert(score>=160,"reach late progression")
 end
end
printh("stage shutter counts "..timed_counts[1]..","..timed_counts[2]..","..
 timed_counts[3]..","..timed_counts[4],"progression_counts.txt",true)
assert(timed_counts[1]==0 and timed_counts[2]>0 and timed_counts[3]>0
 and timed_counts[4]>0,"shutters introduced across stages")
assert(narrow<0.86 and wide>1.07,"constrictions and recovery chambers")
printh("PASS: 18 seeded 160-obstacle runs at top speed and actual speed ramp; narrow "..
 narrow.." wide "..wide,"progression_log.txt",true)
printh("PASS","progression_result.txt",true)

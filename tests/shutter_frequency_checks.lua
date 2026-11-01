_init()
local counts={}
for level=0,2 do
 srand(45) reset_run()
 difficulty_stage=function(n) return level+2 end
 speed=0.5555556
 generated=80 introduced_shutters=level+2 section_end=1000
 choose_route() gates={}
 local count=0
 for i=1,2400 do
  local last=gates[#gates]
  add_gate(last and last.z+last.gap or 35)
  local current=gates[#gates]
  if current.clocked then
   count+=1
   assert(last and not last.rib and not last.clocked,"ordinary guide before each shutter")
  end
  if last and last.clocked then
   assert(not current.clocked and not current.rib,"ordinary guide after each shutter")
  end
  -- Keep the fixture's depth values within PICO-8 numeric range.
  for g in all(gates) do g.z-=current.z-35 end
  while #gates>2 do deli(gates,1) end
 end
 counts[level+1]=count
end
assert(counts[2]>counts[1] and counts[3]>counts[2],"shutter frequency rises through difficulty stages")
assert(counts[3]>counts[1]*2,"late-stage increase is noticeable")
printh("shutters per 2400 gates at stages 2/3/4: "..counts[1]..","..counts[2]..","..counts[3],"shutter_frequency_log.txt",true)
printh("PASS","shutter_frequency_result.txt",true)

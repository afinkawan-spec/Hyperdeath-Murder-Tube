_init()
btn=function(n) return false end
btnp=function(n) return false end
for zone=1,3 do
 reset_run() mode="play" speed=0.8
 visible_zone=zone shape_oval=zones[zone].oval shape_hex=zones[zone].hex
 for i=1,#gates do
  local g=gates[i] g.z=8+(i-1)*24 g.a=0.09+(i-1)*0.08
  g.base_a=g.a g.turn=-0.25 g.clocked=true g.rib=false g.zone=zone
 end
 for phase=0,1 do
  ticks=phase*12
  local before=stat(1)
  _draw() extcmd("screen",3,1)
  assert(stat(1)-before<1,"thick moving-gate edges fit native frame budget")
 end
end
printh("PASS","shutter_visual_result.txt",true)

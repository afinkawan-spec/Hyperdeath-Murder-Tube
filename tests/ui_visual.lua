_init()
btn=function(n) return false end
btnp=function(n) return false end
_draw() extcmd("screen",3,1)
reset_run() mode="play" speed=0 ticks=0
_draw() extcmd("screen",3,1)
speed=0.3 ticks=15
_draw() extcmd("screen",3,1)
mode="dead" impact_age=45 points=1500 points_hi=0 best=1500 best_hi=0 new_record=true ticks=0
_draw() extcmd("screen",3,1)
local pixels={}
for y=43,50 do for x=20,108 do add(pixels,pget(x,y)) end end
ticks=20 _draw() extcmd("screen",3,1)
local index=1 local changed=false
for y=43,50 do for x=20,108 do
 if pixels[index]!=pget(x,y) then changed=true end
 index+=1
end end
assert(changed,"record banner visibly flashes")
new_record=false impact_x=64 impact_y=100
for kind in all({"mine","bolt","gate"}) do
 impact_type=kind _draw() extcmd("screen",3,1)
end
new_record=true impact_type="bolt" _draw() extcmd("screen",3,1)
impact_x=64 impact_y=105
for age in all({0,4,10,18,30,45}) do
 impact_age=age
 local before=stat(1)
 _draw() extcmd("screen",3,1)
 assert(stat(1)-before<1,"large death burst fits frame budget")
end
printh("PASS","ui_visual_result.txt",true)

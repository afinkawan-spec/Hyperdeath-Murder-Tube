_init()
assert(mode=="title","cartridge boots to title")
dset(0,0) dset(1,0) best=0 best_hi=0
local held={}
btn=function(n) return held[n] or false end
btnp=function(n) return false end
_draw()
mode="play"
assert(speed==0,"launch starts at rest")
for frame=1,179 do
 _update60()
 assert(mode=="play" and speed<0.6944444 and #enemies==0,"launch ramps without early enemies")
end
_update60()
assert(abs(speed*1080-750)<0.03 and #enemies>0,"750 km/h and first enemy at three seconds")
assert(peek(0x3200+67)==8 and peek(0x3200+4*68+65)==2,"native sound assets")
reset_run() mode="play" speed=0.6944444
best=0 best_hi=0
local starting_speed=speed
gates[1].z=0.1 angle=gates[1].a
_update60()
assert(speed-starting_speed==0x0.0005,"five km/h per second ramp")
assert(points==100 and best==100,"normal score")
assert(score_text(0,5)=="5" and score_text(1,5)=="10005","score padding preserved")
for n=0,7 do
 assert(peek2(0x3200+n*2)==engine_note,"engine loop notes remain uniform")
end
reset_run() mode="play" speed=0.6944444
gates[1].z=0.1 angle=(gates[1].a+0.155)%1
_update60()
assert(points==100,"edge pass scores ordinary points")
held[5]=true
gates[2].z=0.1 angle=(gates[2].a+0.155)%1
_update60()
assert(points==200,"consecutive edge passes do not build bonuses")
_draw()
gates[3].z=0.1 angle=gates[3].a
_update60()
assert(points==300,"ordinary gate points")
gates[4].z=0.1 angle=(gates[4].a+0.5)%1
_update60()
assert(mode=="dead" and best==300 and impact,"impact")
_draw()
award_points(9600)
for i=1,100 do award_points(450) end
assert(score_text(points_hi,points)=="54900","large score")
assert(dget(0)==4900 and dget(1)==5,"saved high score chunks")
reset_run() mode="play" speed=0.6944444
assert(points==0 and not new_record,"new run clears record banner")
_draw()
reset_run() mode="play" speed=max_speed-0x0.0001
for g in all(gates) do g.z+=1000 end
held[5]=true
_update60()
assert(speed==max_speed,"normal speed clamps at raised cap")
assert(speed==max_speed,"X cannot change flight speed")
reset_run()
assert(speed==0,"new run launches from rest")
printh("PASS", "verify_result.txt", true)

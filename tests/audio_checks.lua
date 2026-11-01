local native_assert=assert
assert=function(value,message)
 if not value then printh("FAIL: "..message,"audio_result.txt",true) end
 return native_assert(value,message)
end
_init()
assert(stat(57),"title ambience pattern starts")
flip()
for channel=0,3 do assert(stat(46+channel)==13+channel,"four-layer title ambience plays") end
local function pitch() return band(engine_note,63) end
local function volume() return band(shr(engine_note,9),7) end
reset_run()
for i=1,3 do flip() end
for channel=0,3 do assert(stat(46+channel)==-1,"starting run stops all title layers") end
mode="play" speed=0.5555556 velocity=0 update_audio()
local idle=pitch()
assert(volume()==2,"idle volume")
velocity=0.0038 update_audio()
assert(engine_turn>0 and engine_turn<0.2,"bank response eases in")
for i=1,45 do update_audio() end
assert(pitch()==idle+3 and volume()==3,"banking raises pitch and volume")
velocity=-0.0038
for i=1,20 do update_audio() end
assert(pitch()==idle+3,"both bank directions get same thrust response")
velocity=0 update_audio()
assert(engine_turn>0.8,"engine response releases gradually")
for i=1,60 do update_audio() end
assert(pitch()==idle and volume()==2,"engine returns to idle tone")
speed=max_speed update_audio()
assert(pitch()>idle,"speed still raises engine pitch")
for n=0,7 do assert(peek2(0x3200+n*2)==engine_note,"uniform notes avoid chuffing") end
for frame=1,90 do
 velocity=frame<45 and 0.0038 or 0
 update_audio()
 if frame%15==0 then sfx(4,1) end
 flip()
 assert(stat(46)==0,"engine remains continuous")
 assert(stat(48)==-1 and stat(49)==-1,"firing leaves hit and explosion channels free")
 assert(not stat(57),"no music playback")
end
-- Charging builds on the gun channel, then loops until release.
reset_run() mode="play" speed=0.5555556 enemy_wait=10000 update_audio()
for g in all(gates) do g.z+=1000 end
local charging=false
btn=function(n) return n==4 and charging end
update_combat() charging=true
for i=1,12 do update_combat() flip() end
assert(stat(47)==7,"held fire produces rising charge sound")
assert(stat(46)==0 and stat(48)==-1 and stat(49)==-1,"charge preserves other channels")
for i=1,24 do update_combat() flip() end
for i=1,30 do update_combat() flip() end
assert(charge==60 and stat(47)==8,"full charge keeps a ready thrum")
charging=false update_combat()
for i=1,3 do flip() end
assert(stat(47)==1,"release replaces thrum with charged blast")
-- Keep the long blast alive through normal firing, charge cancellation and hits.
charging=true
for i=1,12 do update_combat() flip() end
assert(stat(47)==1,"normal fire and charging do not cut charged blast")
charging=false update_combat()
damage_target({kind="fighter",hp=12,max_hp=12,z=24,a=0},0)
damage_target({kind="fighter",hp=1,max_hp=12,z=24,a=0},0)
for i=1,3 do flip() end
assert(stat(47)==1,"hits kills and abandoning charge preserve blast")
for i=1,8 do flip() end
assert(stat(47)==1,"charged blast sustains beyond 0.8 seconds")
local blast_note=peek2(0x3200+68+flr(stat(51))*2)
assert(band(shr(blast_note,9),7)>=2,"late charged sweep stays audible")
for n in all({1,3}) do
 assert(band(shr(peek2(0x3200+68+n*2),9),7)==0,"short gaps separate initial zaps")
end
reset_run() mode="play" speed=0.5555556 enemy_wait=10000 update_audio()
for g in all(gates) do g.z+=1000 end
charging=false update_combat() charging=true
for i=1,12 do update_combat() flip() end
charging=false update_combat()
for i=1,3 do flip() end
assert(stat(47)==-1,"abandoned charge stops winding sound")
reset_run() mode="play" speed=0.5555556 update_audio()

-- Real firing, armour damage and a kill can play together.
local down=false
btn=function(n) return n==4 and down end
for g in all(gates) do g.z+=1000 end
-- Extend only the test gun note so the mixer can be sampled after a frame.
poke(0x3200+4*68+65,8)
local survivor=spawn_pursuit("fighter")
local victim=spawn_pursuit("fighter") victim.hp=1
update_combat() down=true update_combat()
damage_target(survivor,survivor.a)
damage_target(victim,victim.a)
flip()
assert(stat(46)==0 and stat(47)==4 and stat(48)==5 and stat(49)==6,
 "engine gun hit and explosion occupy separate channels")
-- A second press is audible even while the explosion is playing.
down=false update_combat()
fire_cooldown=0 down=true update_combat()
flip()
assert(stat(47)==4 and stat(49)==6,"explosion does not suppress gunshot")
assert(peek(0x3200+68+67)==0,"charged blast cannot loop")
sfx(1,1)
for i=1,3 do flip() end
assert(stat(47)==1,"charged blast uses gun channel")
crash_player(nil,"mine")
for i=1,3 do flip() end
assert(stat(46)==9 and stat(47)==10 and stat(48)==11 and stat(49)==12,"death occupies all four channels")
for i=1,35 do flip() end
for channel=46,49 do assert(stat(channel)==-1,"death layers end without looping") end
btn=function(n) return false end
btnp=function(n) return false end
for i=1,88 do _update60() end
assert(not stat(57),"summary ambience waits for explosion tail")
_update60() flip()
assert(stat(57),"summary ambience starts after explosion")
for channel=0,3 do assert(stat(46+channel)==13+channel,"summary uses all ambience layers") end
reset_run() flip()
assert(not stat(57),"retry stops summary ambience")
assert(engine_turn==0 and engine_note==-1,"retry resets engine response")
printh("PASS","audio_result.txt",true)

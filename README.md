# HYPERDEATH MURDER TUBE
### SCREAMING DOWN THE DEATH HOLE

![Hyperdeath Murder Tube cover art](docs/images/cover.png)

**ONE SHIP. ONE GUN. A COMPLETELY UNREASONABLE AMOUNT OF TUNNEL.**

Strap yourself into a delta-dart death rocket and hurl it down an industrial throat that absolutely does not want you inside it. Bank around the walls. Squeeze through rotating shutters. Thread the ribs. Vaporise anything rude enough to share your airspace.

This is **Hyperdeath Murder Tube**: an endless tunnel runner and arcade shooter for **PICO-8**. A three-second launch throws you up to 750 km/h. Then the speed climbs toward 1,500, the tunnel changes shape, and your sensible decisions become increasingly theoretical.

Tap out laser fire. Hold your nerve for a charged blast that punches through multiple targets. Clear the bombs or dodge them. Kill quickly, because the enemy does not politely leave when the next one arrives.

**There is no finish line. There is your high score, and the wreckage of your previous opinion about how good you were at this.**

## Enter the tube

Download [hyperdeath-murder-tube.p8](hyperdeath-murder-tube.p8) using GitHub's **Download raw file** button. The cartridge contains the whole game; no source files or build step are needed to play.

Open it in **PICO-8**, then run it. On a PC, drag the `.p8` file onto PICO-8 and type `run`. On a compatible handheld, copy it to your PICO-8 cartridge folder and launch it through your usual PICO-8 setup. Ordinary console emulators do not run PICO-8 cartridges.

Windows players with PICO-8 installed in its default location can download the repository ZIP, extract it, and double-click `play-windowed.cmd` for a 512 x 512 window. **Alt+Enter** toggles fullscreen.

## Flight instructions

| Input | Action |
| --- | --- |
| **Left / Right** | Bank around the inside of the tube |
| **Tap Z or X** | Fire a normal shot |
| **Hold Z or X, then release** | Charge for one second and unleash a piercing blast |
| **Z or X** on the title / summary | Start / retry |

On a controller, use the D-pad and either PICO-8 action button (**O / X**). Both fire buttons do the same thing. The charge meter and rising sound tell you when the big shot is ready.

Stay inside the gate openings and steer around the ribs. Moving shutters have yellow faces and red edges. Yellow warning marks show where an enemy burst is aimed: move away before it arrives. Bombs can be shot or dodged. Everything solid is very solid indeed.

Your best score saves between sessions. The run summary reports your score, gates cleared, kills and maximum speed. Beat your record and enjoy a brief, entirely justified flash of superiority.

| In the cockpit | At the starting line |
| :---: | :---: |
| ![Staged in-game combat screenshot](docs/images/gameplay.png) | ![Title screen](docs/images/title.png) |

## Meet the welcoming committee

These enlarged portraits use the actual in-game ship renderer.

| Ship | Identification and recommended attitude |
| :---: | --- |
| ![Green lone fighter](docs/images/fighter.png) | **FIGHTER** — Green, evasive and thoroughly opposed to your continued existence. Wanders around the opening and fires warned bursts. Give it a charged greeting or a sustained argument. |
| ![Orange bomber drone](docs/images/bomber.png) | **BOMBER** — Orange trouble with a cargo hold full of bad decisions. Lays bombs through the openings you wanted to use. Shoot the bombs, shoot the bomber, or develop an urgent interest in the other side of the tunnel. |
| ![Three pink formation fighters](docs/images/formation.png) | **FORMATION** — Three pink pests arriving in sequence, then spreading out to make the tube feel smaller. Occasional bombs and bursts complicate the conversation. Clear the whole group for a bonus; line them up for a particularly satisfying charged shot. |
| ![Purple gunship with cyan engine pods](docs/images/gunship.png) | **HEAVY GUNSHIP** — Purple armour, two big cyan pods, absolutely no social skills. Ordinary shots bounce off. Charge your gun and break both pods. It brings bursts and bombs, and losing an engine does not improve its mood. |

## Under the bonnet

The playable cartridge is ready to go. For editing, rebuilding and running the native checks, see [Development](docs/DEVELOPMENT.md).

Cover illustration generated with OpenAI image generation; game screenshots and enemy portraits captured from PICO-8. Cover art is promotional illustration, not a gameplay screenshot.

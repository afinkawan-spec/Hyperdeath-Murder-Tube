# Development

## Rebuild

Requires Python 3. Run from the repository root:

```sh
python build_cart.py
```

This packages `tunnel.lua`, `combat.lua`, `hazards.lua`, `ship.hex` and the generated native sound data into `hyperdeath-murder-tube.p8`. The build itself uses only Python's standard library. Playtesting requires PICO-8, which is not included.

- `tunnel.lua`: flight, route generation, scenery, scoring and screens.
- `combat.lua`: encounters, player weapons and ship rendering.
- `hazards.lua`: bombs, warned attacks and damage.
- `ship.hex`: player ship sprite.
- `build_cart.py`: cartridge, sprite and sound packaging.

The game launches to 750 km/h in three seconds, then accelerates at approximately 5 km/h/s to 1,500. The fixed-point increment produces about 4.94 km/h/s. Bombs close at 500 km/h. Enemy bursts lock aim at the beginning of a one-second warning.

## Native checks

```sh
python check_game.py
python check_game.py --only hazards
python check_game.py --budget
```

The checker defaults to `C:/Program Files (x86)/PICO-8/pico8.exe`. To use another installation:

```sh
python check_game.py "path/to/pico8.exe"
```

The 21 retained checks cover saves, launch/retry, route progression and transitions, combat, charged shots, bombs, attacks, audio channels and rendering. Test carts, captures and a separate PICO-8 save profile go into ignored `.pico-check/`. Navigation stress tests isolate geometry from combat. Audio checks use a hidden muted native window so the mixer advances.

The abandoned fork prototype and temporary fixed-speed cartridges have been removed from the release project.

## README pictures

`tools/capture_media.py` captures the title and a staged gameplay scene, then renders isolated ship portraits with the real drawing functions. Requires PICO-8 and Pillow (`python -m pip install Pillow`):

```sh
python tools/capture_media.py
```

These fixtures are documentation tooling only and do not enter the shipped cartridge. Intermediate media goes into ignored `.media-capture/`.

## Saved high score

The existing `marc_conduit_20261031_v1` save identifier is deliberately retained so earlier scores survive the rename. `reset-score.p8` clears both high-score chunks when explicitly run in the same PICO-8 installation. Reload the game afterward.

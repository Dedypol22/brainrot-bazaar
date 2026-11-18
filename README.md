# Brainrot Bazaar

A complete 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), built as a Rojo project. The player walks a circular market plaza, buys absurd
original brainrot characters off a conveyor belt, keeps them on their own base plot where they earn
cash every second, climbs a ladder of rarities, mutations and rebirths, and defends the catch from
thieves and from a tsunami wave that sweeps the plaza every few minutes.

## The loop

- Brainrots ride the conveyor through the plaza, one about every 12 seconds. Walk up and click one
  (or its card at the bottom of the screen) to buy it if you can afford it.
- A bought brainrot stands on your base plot and earns cash every second at its own rate.
- Twelve original characters on six rarities — Common, Rare, Epic, Legendary, Mythic, Secret — from
  Bananaphone Barry (12/s) up to Baron Von Wafflefish (17,000/s). Every brainrot can spawn with a
  Golden (x2), Diamond (x5) or Rainbow (x10) mutation.
- Steal from other players' bases by clicking their brainrot and carrying it home — unless their
  base is locked. The owner can lock their base for 45 seconds (2-minute cooldown); touching a thief
  carrying their brainrot makes the thief drop it.
- About every 3 minutes a tsunami warning counts down 10 seconds, then a wave sweeps the plaza,
  washing away every brainrot still on the belt and pushing players outside their base back to spawn.
- Earn $1,000,000 in total to rebirth: cash and brainrots reset, but income rises +25% per rebirth,
  stacking forever. Cash, brainrots, rebirths and extra slots save with DataStore (autosave every
  minute, save on leave), with a safe fallback when Studio runs without API access.

## Layout

- `src/shared/BrainrotCatalog.luau` — the whole cast, rarities, mutations and every tuning number.
- `src/server/MapBuilder.luau` — builds the entire 3D world from Parts (plaza, conveyor, 8 base
  plots, spawn, palms, stalls, clouds, wave wall, lighting).
- `src/server/BrainrotSpawner.luau` — builds brainrot creature models from Parts and rides them
  along the belt.
- `src/server/BaseManager.luau` — plots, slots, base locks and plot signs.
- `src/server/EconomyManager.luau` — the income tick, buys, sells, extra slots and the state
  snapshots the client renders. The server decides all money.
- `src/server/StealManager.luau` — picking up, carrying, dropping and completing a steal.
- `src/server/WaveManager.luau` — the tsunami warning and sweep.
- `src/server/RebirthManager.luau` — rebirth checks and resets.
- `src/server/PlayerData.luau` — loading and saving with DataStore, safe when API access is off.
- `src/server/Main.server.luau` — wires everything together; creates the RemoteEvents.
- `src/client/ClientMain.client.luau` — builds the whole ScreenGui from code (cash and income at
  the top centre, wave banner, conveyor cards at the bottom centre, base panel on the right, Lock
  and Rebirth buttons at the bottom right).

## Rebuild

    /home/hatch/workspace/roblox-game/tools/rojo build default.project.json --output game.rbxl

Then check the hand-in program as the grader does:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and
`PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the
kit's copy, unchanged.

## Publishing (the owner does this in Roblox Studio)

1. Open `game.rbxl` in Roblox Studio, File → Publish to Roblox, as a new Public experience.
2. In Game Settings → Basic Info, write the make.fun play code into the description.
3. On the Creator Dashboard, upload a square icon and thumbnails for the experience; the first
   thumbnail must be the same picture as one of the files in `screenshots/`.
4. Copy the play link, place id and universe id into `PLAY.json`.
5. Take fresh screenshots of the game running in Studio into `screenshots/` (16:9, first by name
   is the cover and the thumbnail).

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.

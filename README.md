[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Dedypol22/brainrot-bazaar/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Dedypol22/brainrot-bazaar/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

# Brainrot Bazaar

A 3D Roblox brainrot tycoon built as a Rojo project. Fifty-two original brainrots
span seven rarities (Common through Divine), and seven mutations can land on any
catch: Golden x2, Candy x3, Diamond x5, Crystal x8, Rainbow x10, Galaxy x15 and
Void x25.

Buy brainrots from the conveyor belt, carry your catch home to your base, and
sell or upgrade as the income rolls in. Rival players can steal from your base by
clicking a placed brainrot, so lock it for 45 seconds (2 minute cooldown) and
remember that every base gets a 30 second shield after a robbery. The Prize Book
index records every brainrot you have ever owned and pays cash prizes at 13, 26,
39 and 52 collected. Raccoon thieves sneak in from the bandit gate; bop one for
$250 and recover its loot. The plaza also rotates events: the sambal tsunami
sweeps anyone caught outside a base back to spawn, and chili rain drops cash
peppers. Rebirth at $1,000,000 total earned for +25% income each time. Progress
saves through DataStore.

## Layout

- `src/shared/BrainrotCatalog.luau` — tuning, rarities, mutations, the 52 characters and helpers.
- `src/server/Main.server.luau` — server bootstrap and remotes.
- `src/server/` — `MapBuilder`, `BaseManager`, `BrainrotSpawner`, `EconomyManager`,
  `PlayerData`, `RebirthManager`, `StealManager`, `ThiefManager`, `WaveManager`.
- `src/client/ClientMain.client.luau` — the HUD, belt/base lists and Prize Book.
- `main.ts` — packages the place, source and screenshots into the make.fun output.

## Publishing

The place is published from Roblox Studio using `game.rbxl` / the Rojo project.

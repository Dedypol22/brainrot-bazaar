[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Dedypol22/brainrot-bazaar/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Dedypol22/brainrot-bazaar/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

# Brainrot Bazaar

A 3D Roblox brainrot tycoon built as a Rojo project. Brainrots ride a conveyor belt through the plaza; buy one, carry it home to your base, and it earns cash every second while it sits on its pad.

**The roster:** 44 original brainrots across 7 rarities — Common, Rare, Epic, Legendary, Mythic, Secret and Divine — from Bananaphone Barry ($150) up to Chef of the Cosmos ($18,000,000). Six mutations can roll on any spawn: Golden (x2), Candy (x3), Diamond (x5), Rainbow (x10), Galaxy (x15) and Void (x25).

**Play loop:**

- Buy from the belt and carry your catch home; bases hold 4 brainrots, expandable to 10 with extra slots.
- Steal from rivals by clicking a brainrot on their base and carrying it home — and lock your own base (45 s lock, 2 min cooldown). A base that was just robbed is shielded for 30 s.
- The **Prize Book** collection index tracks every brainrot you have ever owned and pays cash prizes at 11, 22, 33 and 44 collected ($25,000 / $100,000 / $400,000 / $2,000,000). It survives rebirth.
- Raccoon thieves sneak in from the bandit gate and grab a base's cheapest brainrot. Bop one for $250 and the stolen brainrot goes back to its owner; if it escapes through the gate, the brainrot is gone.
- Rotating plaza events: the **sambal tsunami** sweeps everyone caught outside a base back to spawn, and **chili rain** drops cash peppers (worth $100–$500 each) all over the plaza.
- Rebirth at $1,000,000 total earned for +25% income each time. Progress saves through DataStore.

## Layout

- `src/shared/BrainrotCatalog.luau` — roster, rarities, mutations and tuning.
- `src/server/` — `Main.server.luau` bootstrap plus `MapBuilder`, `BaseManager`, `BrainrotSpawner`, `EconomyManager`, `PlayerData`, `RebirthManager`, `StealManager`, `ThiefManager` and `WaveManager`.
- `src/client/ClientMain.client.luau` — the HUD, including the Prize Book panel.
- `main.ts` — the make.fun entrypoint that assembles the submission dossier.
- `default.project.json` — the Rojo project; `game.rbxl` is its built output.

## Publishing

The place is published from Roblox Studio from `game.rbxl` / the Rojo project.

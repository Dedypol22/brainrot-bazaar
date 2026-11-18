// main.ts — Brainrot Bazaar's make.fun entrypoint.
//
// Copies the game out of this repository — the place file (game.rbxl), the
// play link (PLAY.json), the Luau sources (src/) and the screenshots
// (screenshots/) — into the output directory, then writes dossier.json
// there: exactly the bytes the kit's buildDossier produces from those files,
// so the grader's own rebuild matches byte for byte. The program is run
// twice and must produce identical bytes both times, so nothing here depends
// on the clock, on randomness or on anything outside the repository.

import { copyFileSync, cpSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

mkdirSync(outputDir, { recursive: true });

// Files whose name starts with "." never travel into the output.
const skipDotfiles = (source: string): boolean => !basename(source).startsWith(".");

copyFileSync(join(repoRoot, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outputDir, "PLAY.json"));
cpSync(join(repoRoot, "src"), join(outputDir, "src"), {
  recursive: true,
  filter: skipDotfiles,
});
cpSync(join(repoRoot, "screenshots"), join(outputDir, "screenshots"), {
  recursive: true,
  filter: skipDotfiles,
});

const dossier = buildDossier(outputDir, { text_max_bytes: 65536 });
writeFileSync(join(outputDir, "dossier.json"), dossier);

console.log(
  `Brainrot Bazaar entry written to ${outputDir} (dossier.json: ${dossier.length} bytes)`,
);

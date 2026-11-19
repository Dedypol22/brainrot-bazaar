// Brainrot Bazaar — make.fun entrypoint.
// Copies the built place and its sources into the output directory and
// writes the dossier the scorer expects. Deterministic: no timestamps,
// no randomness, stable ordering everywhere.

import { cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = dirname(fileURLToPath(import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR || "/output";

mkdirSync(outputDir, { recursive: true });

const skipHidden = (source: string): boolean => {
  const name = source.split(/[\\/]/).pop() ?? "";
  return !name.startsWith(".");
};

function copyIntoOutput(relativePath: string): void {
  const from = join(repoRoot, relativePath);
  if (!existsSync(from)) {
    return;
  }
  cpSync(from, join(outputDir, relativePath), {
    recursive: true,
    filter: skipHidden,
  });
}

copyIntoOutput("game.rbxl");
copyIntoOutput("PLAY.json");
copyIntoOutput("src");
copyIntoOutput("screenshots");

const dossier = buildDossier(outputDir, { text_max_bytes: 65536 });
writeFileSync(join(outputDir, "dossier.json"), dossier);

function countCopiedFiles(dir: string): number {
  let total = 0;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) continue;
    if (entry.isDirectory()) total += countCopiedFiles(join(dir, entry.name));
    else if (entry.isFile()) total += 1;
  }
  return total;
}

const copiedCount =
  countCopiedFiles(join(outputDir, "src")) +
  countCopiedFiles(join(outputDir, "screenshots")) +
  (existsSync(join(outputDir, "game.rbxl")) ? 1 : 0) +
  (existsSync(join(outputDir, "PLAY.json")) ? 1 : 0);

console.log(
  `Brainrot Bazaar: copied ${copiedCount} files; dossier written to ${join(outputDir, "dossier.json")}`,
);

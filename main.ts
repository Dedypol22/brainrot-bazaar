// Brainrot Bazaar — make.fun entrypoint.
//
// Copies the game artifacts (game.rbxl, PLAY.json, src/, screenshots/) into
// the output directory and writes dossier.json there: the canonical dossier
// the kit's library builds from those same files. The output is fully
// deterministic — no timestamps, no randomness — so running this twice
// produces byte-identical results.

import { copyFileSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = dirname(fileURLToPath(import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

function copyTree(sourceDir: string, targetDir: string): void {
  mkdirSync(targetDir, { recursive: true });
  const entries = readdirSync(sourceDir, { withFileTypes: true })
    .filter((entry) => !entry.name.startsWith("."))
    .sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  for (const entry of entries) {
    const sourcePath = join(sourceDir, entry.name);
    const targetPath = join(targetDir, entry.name);
    if (entry.isDirectory()) {
      copyTree(sourcePath, targetPath);
    } else if (entry.isFile()) {
      copyFileSync(sourcePath, targetPath);
    }
  }
}

mkdirSync(outputDir, { recursive: true });

for (const fileName of ["game.rbxl", "PLAY.json"]) {
  const sourcePath = join(repoRoot, fileName);
  if (existsSync(sourcePath)) {
    copyFileSync(sourcePath, join(outputDir, fileName));
  }
}
copyTree(join(repoRoot, "src"), join(outputDir, "src"));
copyTree(join(repoRoot, "screenshots"), join(outputDir, "screenshots"));

// buildDossier returns the dossier as canonical JSON bytes (a Uint8Array);
// write them exactly as produced.
const dossierBytes = buildDossier(outputDir, { text_max_bytes: 65536 });
writeFileSync(join(outputDir, "dossier.json"), dossierBytes);

console.log(
  `Brainrot Bazaar: artifacts copied and dossier.json (${dossierBytes.length} bytes) written to ${outputDir}`,
);

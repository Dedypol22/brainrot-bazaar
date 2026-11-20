import { copyFileSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const root = dirname(fileURLToPath(import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR || "/output";

mkdirSync(outputDir, { recursive: true });

let filesCopied = 0;

function copyFile(source: string, destination: string): void {
  copyFileSync(source, destination);
  filesCopied += 1;
}

function copyTree(sourceDir: string, destinationDir: string): void {
  mkdirSync(destinationDir, { recursive: true });
  for (const entry of readdirSync(sourceDir, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) {
      continue;
    }
    const source = join(sourceDir, entry.name);
    const destination = join(destinationDir, entry.name);
    if (entry.isDirectory()) {
      copyTree(source, destination);
    } else if (entry.isFile()) {
      copyFile(source, destination);
    }
  }
}

copyFile(join(root, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFile(join(root, "PLAY.json"), join(outputDir, "PLAY.json"));
copyTree(join(root, "src"), join(outputDir, "src"));
copyTree(join(root, "screenshots"), join(outputDir, "screenshots"));

const dossier = buildDossier(root, { text_max_bytes: 65536 });
if (typeof dossier === "string") {
  writeFileSync(join(outputDir, "dossier.json"), dossier, "utf8");
} else {
  writeFileSync(join(outputDir, "dossier.json"), dossier);
}

console.log(`Wrote Brainrot Bazaar to ${outputDir} (${filesCopied} files copied plus dossier.json).`);

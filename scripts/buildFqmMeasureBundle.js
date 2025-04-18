const fs = require("fs");
const path = require("path");

// Parse --measure-dir
const args = process.argv.slice(2);
let measureDir;

const eqArg = args.find(arg => arg.startsWith("--measure-dir="));
if (eqArg) {
  measureDir = eqArg.split("=")[1];
} else {
  const idx = args.indexOf("--measure-dir");
  if (idx !== -1 && args[idx + 1]) {
    measureDir = args[idx + 1];
  }
}

if (!measureDir) {
  console.error("❌ Usage: node buildMeasureBundle.js --measure-dir=<folder>");
  process.exit(1);
}

const resourcesDir = path.join(measureDir, "resources");
const outputPath = path.join(resourcesDir, "bundle.json");

const bundle = {
  resourceType: "Bundle",
  type: "collection",
  entry: [],
};

// Read all .json files in the resources directory
fs.readdirSync(resourcesDir).forEach(file => {
  if (file.endsWith(".json")) {
    const resource = JSON.parse(fs.readFileSync(path.join(resourcesDir, file), "utf8"));
    bundle.entry.push({ resource });
  }
});

fs.writeFileSync(outputPath, JSON.stringify(bundle, null, 2));
console.log(`✅ Created bundle with ${bundle.entry.length} entries at ${outputPath}`);
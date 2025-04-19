// const fs = require('fs');
// const path = require('path');

// const baseDir = process.argv[2];
// const forceOverwrite = process.argv.includes('--force');

const path = require('path');
const fs = require('fs');

const baseDir = path.resolve(__dirname, '..'); // sets baseDir to one level up from scripts/
const forceOverwrite = process.argv.includes('--force');

if (!baseDir) {
  console.error('❌ Usage: node buildFqmMeasureBundles.js <base-directory> [--force]');
  process.exit(1);
}

const bundleTemplate = {
  resourceType: 'Bundle',
  type: 'collection',
  entry: []
};

function buildBundleForDirectory(resourceDir) {
  const bundle = JSON.parse(JSON.stringify(bundleTemplate));
  const files = fs.readdirSync(resourceDir).filter(f => f.endsWith('.json'));
  for (const file of files) {
    const content = JSON.parse(fs.readFileSync(path.join(resourceDir, file), 'utf8'));
    bundle.entry.push({ resource: content });
  }
  return bundle;
}

const measureDirs = fs.readdirSync(baseDir).filter(f => {
  const fullPath = path.join(baseDir, f);
  return fs.statSync(fullPath).isDirectory();
});

for (const dir of measureDirs) {
  const resourcePath = path.join(baseDir, dir, 'resources');
  const outPath = path.join(resourcePath, 'fqm-bundle.json');

  if (!fs.existsSync(resourcePath)) {
    console.warn(`⚠️  Skipping ${dir} — no resources/ directory found.`);
    continue;
  }

  if (fs.existsSync(outPath) && !forceOverwrite) {
    console.log(`✅ Skipping ${dir} — fqm-bundle.json already exists.`);
    continue;
  }

  try {
    const bundle = buildBundleForDirectory(resourcePath);
    fs.writeFileSync(outPath, JSON.stringify(bundle, null, 2));
    console.log(`✨ Created fqm-bundle.json in ${dir}/resources`);
  } catch (err) {
    console.error(`❌ Failed to build bundle for ${dir}:`, err.message);
  }
}
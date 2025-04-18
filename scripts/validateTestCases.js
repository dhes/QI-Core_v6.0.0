const fs = require('fs');
const path = require('path');
require('dotenv').config();

const args = process.argv.slice(2);
const measureDirArg = args.find(arg => arg.startsWith('--measure-dir='));
const measureDir = measureDirArg
  ? measureDirArg.split('=')[1]
  : process.env.MEASURE_DIR;

if (!measureDir) {
  console.error('❌ No --measure-dir argument or MEASURE_DIR in .env');
  process.exit(1);
}

const TEST_CASES_DIR = path.join(measureDir, 'test-cases');
const REPORT_PATH = path.join(measureDir, 'testCaseValidationReport.txt');

function findAllBundles(dirPath) {
  const bundles = [];
  const dirs = fs.readdirSync(dirPath);
  for (const entry of dirs) {
    const fullPath = path.join(dirPath, entry);
    if (fs.statSync(fullPath).isDirectory()) {
      const files = fs.readdirSync(fullPath).filter(f => f.endsWith('.json'));
      for (const file of files) {
        bundles.push({
          id: entry,
          file: file,
          path: path.join(fullPath, file)
        });
      }
    }
  }
  return bundles;
}

function validateBundle(bundleJson) {
  const allReferences = new Set();
  const allResources = new Set();

  for (const entry of bundleJson.entry || []) {
    const resource = entry.resource;
    if (resource && resource.resourceType && resource.id) {
      allResources.add(`${resource.resourceType}/${resource.id}`);
    }

    const jsonStr = JSON.stringify(resource);
    const referenceMatches = jsonStr.match(/"reference":"(.*?)"/g);
    if (referenceMatches) {
      for (const match of referenceMatches) {
        const reference = match.split(':')[1].replace(/"/g, '');
        if (!reference.startsWith('#')) {
          allReferences.add(reference);
        }
      }
    }
  }

  const orphans = [];
  for (const ref of allReferences) {
    if (!allResources.has(ref)) {
      orphans.push(ref);
    }
  }

  return orphans;
}

// MAIN
console.log(`🔍 Validating bundles in: ${TEST_CASES_DIR}`);
const bundles = findAllBundles(TEST_CASES_DIR);

fs.writeFileSync(REPORT_PATH, `🧪 VALIDATION RUN @ ${new Date().toISOString()}\n`);

let validCount = 0;
let invalidCount = 0;

for (const bundle of bundles) {
  const json = JSON.parse(fs.readFileSync(bundle.path, 'utf-8'));
  const orphans = validateBundle(json);

  if (orphans.length === 0) {
    fs.appendFileSync(REPORT_PATH, `✅ ${bundle.id}/${bundle.file}\n`);
    validCount++;
  } else {
    fs.appendFileSync(REPORT_PATH, `❌ ${bundle.id}/${bundle.file} has ${orphans.length} orphaned references:\n`);
    for (const ref of orphans) {
      fs.appendFileSync(REPORT_PATH, `   ➜ ${ref}\n`);
    }
    invalidCount++;
  }
}

console.log(`✔️ Done. Valid: ${validCount}, Invalid: ${invalidCount}`);
console.log(`📄 Report saved to: ${REPORT_PATH}`);
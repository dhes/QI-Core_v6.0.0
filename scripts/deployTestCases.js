#!/usr/bin/env node

const fs    = require('fs');
const path  = require('path');
const axios = require('axios');
require('dotenv').config();

//─── parse --measure-dir (or MEASURE_DIR in .env)
const argv = process.argv.slice(2);
let measureDir;

// support “--measure-dir=foo”
const eq = argv.find(a => a.startsWith('--measure-dir='));
if (eq) {
  measureDir = eq.split('=')[1];
} else {
  // or “--measure-dir foo”
  const idx = argv.indexOf('--measure-dir');
  if (idx !== -1 && argv[idx+1]) {
    measureDir = argv[idx+1];
  }
}

if (!measureDir) {
  measureDir = process.env.MEASURE_DIR;
}

if (!measureDir) {
  console.error('❌ Usage: node deployTestPatients.js --measure-dir <folder>');
  process.exit(1);
}

const TEST_DIR = path.join(measureDir, 'test-cases');
const LOG_DIR  = 'output';
const LOG_FILE = path.join(LOG_DIR, 'deploy-test-patients-log.txt');
let FHIR_BASE  = process.env.FHIR_SERVER_URL;

if (!FHIR_BASE) {
  console.error('❌ Missing FHIR_SERVER_URL in .env');
  process.exit(1);
}
// ensure no trailing slash
FHIR_BASE = FHIR_BASE.replace(/\/+$/, '') + '/';

// make sure log folder exists
fs.mkdirSync(LOG_DIR, { recursive: true });
fs.appendFileSync(LOG_FILE, `\n🚀 DEPLOY TEST BUNDLES @ ${new Date().toISOString()}\n`);

async function deployBundle(bundle, name) {
  try {
    await axios.post(FHIR_BASE, bundle, {
      headers: { 'Content-Type': 'application/fhir+json' }
    });
    console.log(`✅ ${name}`);
    fs.appendFileSync(LOG_FILE, `✅ ${name}\n`);
    return true;
  }
  catch (err) {
    const msg = err.response?.data || err.message;
    console.error(`❌ ${name} → ${JSON.stringify(msg)}`);
    fs.appendFileSync(LOG_FILE, `❌ ${name} → ${JSON.stringify(msg)}\n`);
    return false;
  }
}

(async () => {
  if (!fs.existsSync(TEST_DIR)) {
    console.error(`❌ Test‑cases folder not found: ${TEST_DIR}`);
    process.exit(1);
  }

  const patientFolders = fs.readdirSync(TEST_DIR)
    .filter(d => fs.statSync(path.join(TEST_DIR, d)).isDirectory());

  let total = 0, succeeded = 0, failed = 0;

  for (const pat of patientFolders) {
    const bundleFiles = fs.readdirSync(path.join(TEST_DIR, pat))
      .filter(f => f.endsWith('.json'));

    for (const file of bundleFiles) {
      const filePath = path.join(TEST_DIR, pat, file);
      let bundle;
      try {
        bundle = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (e) {
        console.error(`❌ parse error ${filePath}: ${e.message}`);
        continue;
      }

      // name for logging
      const name = `${pat}/${file}`;
      total++;
      const ok = await deployBundle(bundle, name);
      if (ok) succeeded++;
      else failed++;
    }
  }

  console.log(`\n📊 Done: ${succeeded}/${total} bundles succeeded, ${failed} failed`);
  fs.appendFileSync(LOG_FILE, `📊 ${succeeded}/${total} succeeded, ${failed} failed\n`);
})();
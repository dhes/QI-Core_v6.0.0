#!/usr/bin/env node

/**
 * scripts/deployResourcesToHAPI.js
 *
 * Usage:
 *   node scripts/deployResourcesToHAPI.js --measure-dir=CMS69-bmi_0.3.000
 *
 * It will:
 *   • Read every .json in <measure-dir>/resources
 *   • Parse out resourceType & id from each file
 *   • PUT to [FHIR_SERVER_URL]/<resourceType>/<id>
 *   • Log to output/deploy-resources-log.txt
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');
require('dotenv').config();

// pick up your FHIR server base from .env
const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;
if (!FHIR_SERVER_URL) {
  console.error('❌ Please set FHIR_SERVER_URL in your .env');
  process.exit(1);
}

// parse --measure-dir
const args = process.argv;
const mdIndex = args.indexOf('--measure-dir');
if (mdIndex === -1 || !args[mdIndex + 1]) {
  console.error('❌ Usage: --measure-dir=<folder>');
  process.exit(1);
}
const measureDir = args[mdIndex + 1];
const resourcesDir = path.join(measureDir, 'resources');

// prepare logging
// fs.mkdirSync('output', { recursive: true });
// const logFile = path.join('output', 'deploy-resources-log.txt');
const logDir = path.join(measureDir, 'output');
fs.mkdirSync(logDir, { recursive: true });
const logFile = path.join(logDir, 'deploy-resources-log.txt');fs.appendFileSync(logFile, `\n🚀 DEPLOY RUN @ ${new Date().toISOString()}\n`);

async function deployResource(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  let resrc;
  try {
    resrc = JSON.parse(raw);
  } catch (e) {
    console.error(`❌ ${filePath} — invalid JSON`);
    fs.appendFileSync(logFile, `❌ ${filePath} — invalid JSON\n`);
    return;
  }

  const { resourceType, id } = resrc;
  if (!resourceType || !id) {
    console.error(`❌ ${filePath} — missing resourceType or id`);
    fs.appendFileSync(logFile, `❌ ${filePath} — missing resourceType or id\n`);
    return;
  }

  const url = `${FHIR_SERVER_URL.replace(/\/$/,'')}/${resourceType}/${id}`;
  try {
    await axios.put(url, resrc, {
      headers: { 'Content-Type': 'application/fhir+json' }
    });
    console.log(`✅ PUT ${resourceType}/${id}`);
    fs.appendFileSync(logFile, `✅ PUT ${resourceType}/${id}\n`);
  } catch (err) {
    const msg = err.response?.data || err.message;
    console.error(`❌ PUT ${resourceType}/${id} —`, msg);
    fs.appendFileSync(logFile, `❌ PUT ${resourceType}/${id} — ${JSON.stringify(msg)}\n`);
  }
}

async function run() {
  if (!fs.existsSync(resourcesDir)) {
    console.error(`❌ resources folder not found: ${resourcesDir}`);
    process.exit(1);
  }

  const files = fs.readdirSync(resourcesDir)
    .filter(f => f.endsWith('.json') && f !== "fqm-bundle.json");

  console.log(`📦 Found ${files.length} resources under ${resourcesDir}`);
  for (const filename of files) {
    const fullPath = path.join(resourcesDir, filename);
    // skip any backups / stashes if you want:
    if (filename.startsWith('.')) continue;
    await deployResource(fullPath);
  }

  console.log(`🧾 Done.  Log → ${logFile}`);
}

run();
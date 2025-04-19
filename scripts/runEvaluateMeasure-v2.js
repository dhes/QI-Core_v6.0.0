#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const axios = require("axios");
require("dotenv").config();

const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;

// parse command line args
const args = process.argv.slice(2);

let measureDir;
let measureId;

const mdFlag = args.find(a => a.startsWith('--measure-dir='));
const midFlag = args.find(a => a.startsWith('--measure-id='));
if (mdFlag) measureDir = mdFlag.split('=')[1];
if (midFlag) measureId = midFlag.split('=')[1];

if (!measureDir || !measureId) {
  console.error('❌ Usage: node runEvaluateMeasure.js --measure-dir=<folder> --measure-id=<MeasureId>');
  process.exit(1);
}

const testCasesDir = path.join(measureDir, "test-cases");
const logFile = path.join(measureDir, "test-case-eval-report.txt");
fs.writeFileSync(logFile, `📋 Test Case Report @ ${new Date().toISOString()}\n\n`);
console.log("Looking for test cases in:", testCasesDir);

function extractPeriod(bundle) {
  const report = bundle.entry.find(e => e.resource.resourceType === "MeasureReport")?.resource;
  return report?.period || {};
}

function extractExpectedValues(bundle) {
  const report = bundle.entry.find(e => e.resource.resourceType === "MeasureReport")?.resource;
  const counts = {};
  if (!report || !report.group) return counts;

  for (const group of report.group) {
    for (const pop of group.population || []) {
      const code = pop.code?.coding?.[0]?.code;
      counts[code] = pop.count;
    }
    if (group.measureScore) counts.measureScore = group.measureScore.value;
  }
  return counts;
}

function extractActualValues(report) {
  const counts = {};
  for (const group of report.group || []) {
    for (const pop of group.population || []) {
      const code = pop.code?.coding?.[0]?.code;
      counts[code] = pop.count;
    }
    if (group.measureScore) counts.measureScore = group.measureScore.value;
  }
  return counts;
}

function formatCounts(counts) {
  const order = [
    "initial-population",
    "denominator",
    "denominator-exclusion",
    "numerator",
    "denominator-exception"
  ];
  return order.map(code => `${code}=${counts[code] ?? 0}`).join(", ") +
         ", measureScore=" + (counts.measureScore ?? "—");
}

function compareCounts(expected, actual) {
  const codes = [
    "initial-population",
    "denominator",
    "denominator-exclusion",
    "numerator",
    "denominator-exception",
    "measureScore"
  ];
  for (const code of codes) {
    if ((expected[code] ?? 0) !== (actual[code] ?? 0)) return false;
  }
  return true;
}

(async () => {
  const patientDirs = fs.readdirSync(testCasesDir).filter(f => {
    const full = path.join(testCasesDir, f);
    return fs.statSync(full).isDirectory();
  });

  console.log(`▶ Found ${patientDirs.length} test case bundles`);

  for (const dir of patientDirs) {
    const patientPath = path.join(testCasesDir, dir);
    const files = fs.readdirSync(patientPath).filter(f => f.endsWith(".json"));
    if (files.length === 0) continue;

    const fullPath = path.join(patientPath, files[0]);
    const bundle = JSON.parse(fs.readFileSync(fullPath, "utf8"));

    const period = extractPeriod(bundle);
    const expected = extractExpectedValues(bundle);

    const patient = dir;
    const query = `${FHIR_SERVER_URL}Measure/${measureId}/$evaluate-measure?subject=Patient/${patient}&periodStart=${period.start}&periodEnd=${period.end}`;

    try {
      const res = await axios.get(query);
      const actual = extractActualValues(res.data);
      const ok = compareCounts(expected, actual);
      const line = `-- ${ok ? "✅" : "❌"} ${fullPath}\n   expected [${formatCounts(expected)}]\n   actual   [${formatCounts(actual)}]\n`;
      console.log(line);
      fs.appendFileSync(logFile, line);
    } catch (err) {
      const msg = err.response?.status || err.message;
      console.log(`-- ❌ ${fullPath} — ${msg}`);
      fs.appendFileSync(logFile, `❌ ${fullPath} — ${msg}\n`);
    }
  }

  console.log(`📄 Done. Full report → ${logFile}`);
})();

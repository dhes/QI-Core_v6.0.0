#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const axios = require("axios");
require("dotenv").config();

const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;

const args = process.argv.slice(2);
let measureDir, measureId;

// Parse args like "--measure-dir=foo" or "--measure-dir foo"
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith("--measure-dir=")) {
    measureDir = args[i].split("=")[1];
  } else if (args[i] === "--measure-dir") {
    measureDir = args[i + 1];
    i++;
  } else if (args[i].startsWith("--measure-id=")) {
    measureId = args[i].split("=")[1];
  } else if (args[i] === "--measure-id") {
    measureId = args[i + 1];
    i++;
  }
}

if (!measureDir || !measureId) {
  console.error("❌ Usage: node runEvaluateMeasure.js --measure-dir <folder> --measure-id <measureId>");
  process.exit(1);
}

const testCasesDir = path.join(measureDir, "test-cases");
const logFile = path.join(measureDir, "test-case-eval-report.txt");
fs.writeFileSync(logFile, `📋 Test Case Report @ ${new Date().toISOString()}\n\n`);

// Only include real directories like UUIDs
const testCaseDirs = fs.readdirSync(testCasesDir)
  .map(name => path.join(testCasesDir, name))
  .filter(p => fs.existsSync(p) && fs.statSync(p).isDirectory());

console.log("Looking for test cases in:", testCasesDir);
console.log(`▶ Found ${testCaseDirs.length} test case bundles`);

function plural(n, label) {
  return `${label}=${n}`;
}

async function run() {
  for (const testDir of testCaseDirs) {
    const patientId = path.basename(testDir);
    const bundlePath = fs.readdirSync(testDir)
      .map(f => path.join(testDir, f))
      .find(f => f.endsWith(".json") && fs.statSync(f).isFile());

    if (!bundlePath) {
      console.log(`⚠️  No .json bundle found in ${testDir}`);
      continue;
    }

    const fileName = path.relative(measureDir, bundlePath);
    process.stdout.write(`-- Processing: ${fileName} `);

    // Read bundle to extract measurement period
    let periodStart, periodEnd;
    try {
      const bundle = JSON.parse(fs.readFileSync(bundlePath, "utf8"));
      const mp = bundle.entry.find(e =>
        e.resource?.resourceType === "MeasureReport" &&
        e.resource.period?.start &&
        e.resource.period?.end
      )?.resource?.period;

      if (!mp) {
        throw new Error("❌ No MeasureReport.period found");
      }

      periodStart = mp.start;
      periodEnd = mp.end;
    } catch (err) {
      console.error(`❌ Failed to extract period: ${err.message}`);
      fs.appendFileSync(logFile, `❌ ${fileName} — failed to parse bundle\n`);
      continue;
    }

    try {
      const url = `${FHIR_SERVER_URL}Measure/${measureId}/$evaluate-measure?` +
        `subject=Patient/${patientId}&periodStart=${periodStart}&periodEnd=${periodEnd}`;
      const res = await axios.get(url);
      const report = res.data;

      const group = report.group?.[0];
      if (!group) throw new Error("No group in MeasureReport");

      const score = group.measureScore?.value?.toFixed(2) ?? "—";
      const popCounts = group.population
        .map(p => plural(p.count, p.code.coding[0].code))
        .join(", ");

      console.log(`✅ ${fileName}`);
      fs.appendFileSync(logFile,
        `✅ ${fileName}\n   ${popCounts}, measureScore=${score}\n`
      );

    } catch (err) {
      const status = err.response?.status || "???";
      console.error(`❌ ${fileName} — ${status}`);
      fs.appendFileSync(logFile, `❌ ${fileName} — ${status}\n`);
    }
  }

  console.log(`📄 Wrote test results to ${logFile}`);
}

run();
#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const axios = require("axios");
require("dotenv").config();

const args = process.argv.slice(2);
let measureDir, measureId;

// Parse command-line args
const eqDir = args.find((a) => a.startsWith("--measure-dir="));
if (eqDir) {
  measureDir = eqDir.split("=")[1];
} else {
  const idx = args.indexOf("--measure-dir");
  if (idx !== -1 && args[idx + 1]) measureDir = args[idx + 1];
}

const eqId = args.find((a) => a.startsWith("--measure-id="));
if (eqId) {
  measureId = eqId.split("=")[1];
} else {
  const idx = args.indexOf("--measure-id");
  if (idx !== -1 && args[idx + 1]) measureId = args[idx + 1];
}

if (!measureDir || !measureId) {
  console.error("❌ Usage: node runEvaluateMeasureActualOnly.js --measure-dir <dir> --measure-id <id>");
  process.exit(1);
}

const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;
const testCasesDir = path.join(measureDir, "test-cases");
const logFile = path.join(measureDir, "actual-eval-report.txt");
const csvFile = path.join(measureDir, "actual-eval-report.csv");

// Initialize logs
fs.writeFileSync(logFile, `📋 HAPI Evaluation Report @ ${new Date().toISOString()}\n\n`);
fs.writeFileSync(csvFile, ["test-patient id", "IP", "D", "DX", "N", "NX", "DE", "MS", "eMS"].join(",") + "\n");

const patientDirs = fs
  .readdirSync(testCasesDir)
  .filter((f) => !f.startsWith(".") && fs.statSync(path.join(testCasesDir, f)).isDirectory());

console.log("▶ Found", patientDirs.length, "test case bundles");

(async () => {
  for (const patientId of patientDirs) {
    const patientPath = path.join(testCasesDir, patientId);
    const jsonFile = fs.readdirSync(patientPath).find((f) => f.endsWith(".json"));
    if (!jsonFile) continue;

    const bundlePath = path.join(patientPath, jsonFile);
    const bundle = JSON.parse(fs.readFileSync(bundlePath, "utf8"));
    const mr = bundle.entry.find((e) => e.resource.resourceType === "MeasureReport");
    const period = mr?.resource?.period;
    const periodStart = period?.start;
    const periodEnd = period?.end;

    const url = `${FHIR_SERVER_URL}Measure/${measureId}/$evaluate-measure?subject=Patient/${patientId}&periodStart=${periodStart}&periodEnd=${periodEnd}`;
    process.stdout.write(`-- Processing: ${path.join("test-cases", patientId, jsonFile)} `);

    try {
      const res = await axios.get(url);
      const group = res.data.group?.[0]?.population || [];
      const counts = { IP: 0, D: 0, DX: 0, N: 0, NX: 0, DE: 0 };

      for (const pop of group) {
        const code = pop.code?.coding?.[0]?.code;
        const count = pop.count ?? 0;
        if (code === "initial-population") counts.IP = count;
        if (code === "denominator") counts.D = count;
        if (code === "denominator-exclusion") counts.DX = count;
        if (code === "numerator") counts.N = count;
        if (code === "numerator-exclusion") counts.NX = count;
        if (code === "denominator-exception") counts.DE = count;
      }

      const MS = res.data.group?.[0]?.measureScore?.value ?? null;
      const TD = counts.D === 1 && counts.DX === 0 && counts.DE === 0;
      const TN = TD && counts.N === 1 && counts.NX === 0;
      const eMS = TD ? (TN ? 1.0 : 0.0) : null;

      fs.appendFileSync(
        logFile,
        `✅ ${path.join("test-cases", patientId, jsonFile)}\n   IP=${counts.IP}, D=${counts.D}, DX=${counts.DX}, N=${counts.N}, NX=${counts.NX}, DE=${counts.DE}, MS=${MS}, eMS=${eMS}\n`
      );

      fs.appendFileSync(
        csvFile,
        [patientId, counts.IP, counts.D, counts.DX, counts.N, counts.NX, counts.DE, MS, eMS].join(",") + "\n"
      );
    } catch (err) {
      const msg = err.response?.status || err.message;
      fs.appendFileSync(logFile, `❌ ${path.join("test-cases", patientId, jsonFile)} — ${msg}\n`);
      console.log(`❌ ${path.join("test-cases", patientId, jsonFile)} — ${msg}`);
    }
  }
})();
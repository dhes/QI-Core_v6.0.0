//!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const axios = require("axios");
require("dotenv").config();

const args = process.argv.slice(2);

let measureDir, measureId;
const eqDir = args.find((a) => a.startsWith("--measure-dir="));
if (eqDir) {
  measureDir = eqDir.split("=")[1];
} else {
  const idx = args.indexOf("--measure-dir");
  if (idx !== -1 && args[idx + 1]) {
    measureDir = args[idx + 1];
  }
}

const eqId = args.find((a) => a.startsWith("--measure-id="));
if (eqId) {
  measureId = eqId.split("=")[1];
} else {
  const idx = args.indexOf("--measure-id");
  if (idx !== -1 && args[idx + 1]) {
    measureId = args[idx + 1];
  }
}

if (!measureDir || !measureId) {
  console.error("❌ Usage: node runEvaluateMeasure.js --measure-dir <dir> --measure-id <id>");
  process.exit(1);
}

const FHIR_SERVER_URL = process.env.FHIR_SERVER_URL;
const testCasesDir = path.join(measureDir, "test-cases");
const logFile = path.join(measureDir, "test-case-eval-report.txt");
const csvFile = path.join(measureDir, "test-case-eval-report.csv");
fs.writeFileSync(logFile, `📋 Test Case Report @ ${new Date().toISOString()}\n\n`);
fs.writeFileSync(
  csvFile,
  [
    "test-patient id",
    "expected initial-population",
    "expected denominator",
    "expected denominator-exclusion",
    "expected denominator-exception",
    "expected numerator",
    "expected measureScore",
    "actual initial-population",
    "actual denominator",
    "actual denominator-exclusion",
    "actual denominator-exception",
    "actual numerator",
    "actual measureScore"
  ].join(",") + "\n"
);

console.log("Looking for test cases in:", testCasesDir);

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

    const expected = { ip: "—", denom: "—", denex: "—", denexcep: "—", numer: "—", score: "—" };
    const mr = bundle.entry.find((e) => e.resource.resourceType === "MeasureReport");
    if (mr) {
      const populations = mr.resource.group?.[0]?.population || [];
      for (const pop of populations) {
        const code = pop.code?.coding?.[0]?.code;
        const count = pop.count ?? "—";
        if (code === "initial-population") expected.ip = count;
        if (code === "denominator") expected.denom = count;
        if (code === "denominator-exclusion") expected.denex = count;
        if (code === "denominator-exception") expected.denexcep = count;
        if (code === "numerator") expected.numer = count;
      }
      expected.score = mr.resource.group?.[0]?.measureScore?.value ?? "—";
    }

    const period = mr?.resource?.period;
    const periodStart = period?.start;
    const periodEnd = period?.end;

    const url = `${FHIR_SERVER_URL}Measure/${measureId}/$evaluate-measure?` +
                `subject=Patient/${patientId}&periodStart=${periodStart}&periodEnd=${periodEnd}`;

    process.stdout.write(`-- Processing: ${path.join("test-cases", patientId, jsonFile)} `);

    try {
      const res = await axios.get(url);
      const actual = { ip: "—", denom: "—", denex: "—", denexcep: "—", numer: "—", score: "—" };
      const group = res.data.group?.[0]?.population || [];
      for (const pop of group) {
        const code = pop.code?.coding?.[0]?.code;
        const count = pop.count ?? "—";
        if (code === "initial-population") actual.ip = count;
        if (code === "denominator") actual.denom = count;
        if (code === "denominator-exclusion") actual.denex = count;
        if (code === "denominator-exception") actual.denexcep = count;
        if (code === "numerator") actual.numer = count;
      }
      actual.score = res.data.group?.[0]?.measureScore?.value ?? "—";

      fs.appendFileSync(
        logFile,
        `✅ ${path.join("test-cases", patientId, jsonFile)}\n   initial-population=${actual.ip}, denominator=${actual.denom}, denominator-exclusion=${actual.denex}, numerator=${actual.numer}, denominator-exception=${actual.denexcep}, measureScore=${actual.score}\n`
      );

      fs.appendFileSync(
        csvFile,
        [
          patientId.slice(0, 8),
          expected.ip, expected.denom, expected.denex, expected.denexcep, expected.numer, expected.score,
          actual.ip, actual.denom, actual.denex, actual.denexcep, actual.numer, actual.score
        ].join(",") + "\n"
      );
    } catch (err) {
      const msg = err.response?.status || err.message;
      fs.appendFileSync(logFile, `❌ ${path.join("test-cases", patientId, jsonFile)} — ${msg}\n`);
      console.log(`❌ ${path.join("test-cases", patientId, jsonFile)} — ${msg}`);
    }
  }
})();

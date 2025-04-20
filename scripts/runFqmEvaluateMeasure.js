#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

require("dotenv").config();

const args = process.argv.slice(2);
let measureDir = args.find((a) => a.startsWith("--measure-dir="));
if (!measureDir) {
  const idx = args.indexOf("--measure-dir");
  if (idx !== -1 && args[idx + 1]) {
    measureDir = args[idx + 1];
  }
}
if (!measureDir) {
  console.error("❌ Usage: node runFqmEvaluateMeasure.js --measure-dir <dir>");
  process.exit(1);
}

const testCasesDir = path.join(measureDir, "test-cases");
const resourcesDir = path.join(measureDir, "resources");
const bundlePath = path.join(resourcesDir, "fqm-bundle.json");
const logFile = path.join(measureDir, "test-case-eval-fqm.txt");
const csvFile = path.join(measureDir, "test-case-eval-fqm.csv");
fs.writeFileSync(logFile, `📋 FQM Test Case Report @ ${new Date().toISOString()}\n\n`);
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

const patientDirs = fs.readdirSync(testCasesDir).filter(f =>
  fs.statSync(path.join(testCasesDir, f)).isDirectory()
);

const patientFiles = [];
const expectations = {};
let measurementPeriodStart, measurementPeriodEnd;

for (const pid of patientDirs) {
  const folder = path.join(testCasesDir, pid);
  const file = fs.readdirSync(folder).find(f => f.endsWith(".json"));
  if (!file) continue;

  const fullPath = path.join(folder, file);
  const bundle = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  const mr = bundle.entry.find(e => e.resource.resourceType === "MeasureReport")?.resource;

  const getCount = (code) => {
    return (
      mr?.group?.[0]?.population?.find(p => p.code?.coding?.[0]?.code === code)?.count ?? "—"
    );
  };

  expectations[pid] = {
    ip: getCount("initial-population"),
    denom: getCount("denominator"),
    denex: getCount("denominator-exclusion"),
    denexcep: getCount("denominator-exception"),
    numer: getCount("numerator"),
    score: mr?.group?.[0]?.measureScore?.value ?? "—"
  };

  measurementPeriodStart = mr?.period?.start;
  measurementPeriodEnd = mr?.period?.end;

  patientFiles.push(fullPath);
}

const outPath = path.resolve(measureDir, "fqm-eval-output.json");

const VSAC_API_KEY = process.env.VSAC_API_KEY || "";
const fqmCommand = `fqm-execution reports \
  --measure-bundle ${bundlePath} \
  --patient-bundles ${patientFiles.join(" ")} \
  --report-type individual \
  --measurement-period-start ${measurementPeriodStart} \
  --measurement-period-end ${measurementPeriodEnd} \
  --vs-api-key ${VSAC_API_KEY} \
  --slim \
  -o ${outPath}`;

try {
  console.log("🧮 Running FQM...");
  execSync(fqmCommand, { stdio: "inherit" });
  console.log("✅ FQM run complete.");
} catch (err) {
  console.error("❌ FQM run failed:", err.message);
  process.exit(1);
}

if (!fs.existsSync(outPath)) {
  console.error(`❌ Expected output file not found at ${outPath}`);
  process.exit(1);
}

const reports = JSON.parse(fs.readFileSync(outPath, "utf8"));

for (const report of reports) {
  const pid = report.subject?.reference?.split("/")[1];
  const shortId = pid?.slice(0, 8);
  const expected = expectations[pid] || {};

  const getPop = (code) => {
    return (
      report.group?.[0]?.population?.find(p => p.code?.coding?.[0]?.code === code)?.count ?? "—"
    );
  };

  const actual = {
    ip: getPop("initial-population"),
    denom: getPop("denominator"),
    denex: getPop("denominator-exclusion"),
    denexcep: getPop("denominator-exception"),
    numer: getPop("numerator"),
    score: report.group?.[0]?.measureScore?.value ?? "—"
  };

  fs.appendFileSync(
    logFile,
    `✅ Patient ${pid}\n   initial-population=${actual.ip}, denominator=${actual.denom}, denominator-exclusion=${actual.denex}, numerator=${actual.numer}, denominator-exception=${actual.denexcep}, measureScore=${actual.score}\n`
  );

  fs.appendFileSync(
    csvFile,
    [
      shortId,
      expected.ip, expected.denom, expected.denex, expected.denexcep, expected.numer, expected.score,
      actual.ip, actual.denom, actual.denex, actual.denexcep, actual.numer, actual.score
    ].join(",") + "\n"
  );
}
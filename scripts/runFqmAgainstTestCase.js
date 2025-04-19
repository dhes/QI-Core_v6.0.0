#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// Parse arguments
const args = process.argv.slice(2);
let measureDir, patientBundle;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--measure-dir" && args[i + 1]) {
    measureDir = args[i + 1];
  } else if (args[i] === "--patient-bundles" && args[i + 1]) {
    patientBundle = args[i + 1];
  }
}

if (!measureDir || !patientBundle) {
  console.error(
    "❌ Usage: node runFqmAgainstTestCase.js --measure-dir <folder> --patient-bundles <file>"
  );
  process.exit(1);
}

// Load the patient bundle and extract the Measurement Period
let rawBundle;
try {
  rawBundle = JSON.parse(fs.readFileSync(patientBundle, "utf8"));
} catch (err) {
  console.error("❌ Failed to read patient bundle:", err.message);
  process.exit(1);
}

const measureReport = rawBundle.entry.find(
  (e) => e.resource.resourceType === "MeasureReport"
)?.resource;

if (!measureReport || !measureReport.period) {
  console.error("❌ Could not find MeasureReport with a period in the bundle.");
  process.exit(1);
}

const periodStart = measureReport.period.start;
const periodEnd = measureReport.period.end;
const bundlePath = path.join(measureDir, "resources", "fqm-bundle.json");

require("dotenv").config();
const VSAC_API_KEY = process.env.VSAC_API_KEY;

// Build the FQM command
const command = `fqm-execution reports \
  --slim \
  --measure-bundle ${bundlePath} \
  --patient-bundles ${patientBundle} \
  --report-type individual \
  --measurement-period-start ${periodStart} \
  --measurement-period-end ${periodEnd} \
  --vs-api-key ${VSAC_API_KEY}`;

console.log("🚀 Running fqm-execution:");
console.log(command);

try {
  const result = execSync(command, { encoding: "utf8" });

  const outputPath = path.join(measureDir, "fqm-output.json");
  fs.writeFileSync(outputPath, result);

  console.log(`\n✅ MeasureReport saved to ${outputPath}`);
} catch (err) {
  console.error("❌ fqm-execution failed:", err.message);
  process.exit(1);
}

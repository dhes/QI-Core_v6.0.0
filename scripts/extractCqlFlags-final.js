const fs = require("fs");
const path = require("path");
const { Calculator } = require("fqm-execution");
const csvWriter = require("csv-writer").createObjectCsvWriter;

const measureBundlePath = "CMS69-bmi_0.3.000/resources/fqm-bundle.json";
const testCasesDir = "CMS69-bmi_0.3.000/test-cases";
const outputCsv = "cql-flags.csv";
const valueSetCacheDir = path.resolve("./cache/terminology");

const interestingFlags = [
  "Initial Population",
  "Denominator",
  "Denominator Exclusions",
  "Denominator Exceptions",
  "Numerator"
];

const valueSetCache = [];
if (fs.existsSync(valueSetCacheDir)) {
  fs.readdirSync(valueSetCacheDir).forEach((file) => {
    if (file.endsWith(".json")) {
      try {
        valueSetCache.push(
          JSON.parse(fs.readFileSync(path.join(valueSetCacheDir, file), "utf8"))
        );
      } catch (e) {
        console.warn("Failed to parse value set:", file, e.message);
      }
    }
  });
}

const options = {
  measurementPeriodStart: "2026-01-01",
  measurementPeriodEnd: "2026-12-31",
  reportType: "individual",
  calculateSDEs: false,
  calculateHTML: false,
  calculateDRC: false,
  includeClauseResults: false,
  calculateClauseCoverage: false,
  verboseCalculationResults: false,
};

async function runAllTestCases() {
  const measureBundle = JSON.parse(fs.readFileSync(measureBundlePath));
  const writer = csvWriter({
    path: outputCsv,
    header: [
      { id: "patientId", title: "test-patient-id" },
      ...interestingFlags.map(f => ({ id: f.replace(/\s+/g, ""), title: f }))
    ]
  });

  const results = [];
  const testCaseDirs = fs.readdirSync(testCasesDir);

  for (const dir of testCaseDirs) {
    const fullDirPath = path.join(testCasesDir, dir);
    if (!fs.statSync(fullDirPath).isDirectory()) continue;

    const bundleFiles = fs
      .readdirSync(fullDirPath)
      .filter((f) => f.endsWith(".json"));
    if (bundleFiles.length === 0) continue;

    const bundlePath = path.join(fullDirPath, bundleFiles[0]);
    const patientBundle = JSON.parse(fs.readFileSync(bundlePath));

    try {
      const raw = await Calculator.calculateRaw(
        measureBundle,
        [patientBundle],
        options,
        valueSetCache
      );

      // Try patientResults first
      let patientId = Object.keys(raw.patientResults || {})[0];
      let resultBlock = raw.patientResults?.[patientId];

      // Fall back to unfilteredResults if needed
      if (!resultBlock || Object.keys(resultBlock).length === 0) {
        patientId = Object.keys(raw.unfilteredResults || {})[0];
        resultBlock = raw.unfilteredResults?.[patientId];

        if (!resultBlock || Object.keys(resultBlock).length === 0) {
          console.warn(`No usable CQL results for: ${dir}`);
          continue;
        }
      }

      const row = { patientId };
      for (const flag of interestingFlags) {
        const rawVal = resultBlock[flag];
        row[flag.replace(/\s+/g, "")] = rawVal === true;
      }

      results.push(row);

    } catch (error) {
      console.warn(`Error processing ${dir}:`, error.message);
    }
  }

  await writer.writeRecords(results);
  console.log(`✅ CSV written to: ${outputCsv}`);
}

runAllTestCases().catch((e) => {
  console.error("Fatal error:", e);
});
const fs = require("fs");
const path = require("path");
const { Calculator } = require("fqm-execution");
const csvWriter = require("csv-writer").createObjectCsvWriter;

const measureBundlePath = "CMS69-bmi_0.3.000/resources/fqm-bundle.json";
const testCasesDir = "CMS69-bmi_0.3.000/test-cases";

const outputCsv = "cql-results.csv";

const valueSetCacheDir = path.resolve("./cache/terminology");

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
      { id: "InitialPopulation", title: "Initial Population" },
      { id: "Denominator", title: "Denominator" },
      { id: "DenominatorExclusions", title: "Denominator Exclusions" },
      { id: "DenominatorExceptions", title: "Denominator Exceptions" },
      { id: "Numerator", title: "Numerator" },
    ],
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

    const raw = await Calculator.calculateRaw(
      measureBundle,
      [patientBundle],
      options,
      valueSetCache
    );

    if (!raw.patientResults || Object.keys(raw.patientResults).length === 0) {
      console.warn(`No patient results for: ${dir}`);
      continue;
    }

    const patientId = Object.keys(raw.patientResults)[0];
    const cqlResults = raw.patientResults[patientId];

    results.push({
      patientId,
      InitialPopulation: !!cqlResults["Initial Population"],
      Denominator: !!cqlResults["Denominator"],
      DenominatorExclusions: !!cqlResults["Denominator Exclusions"],
      DenominatorExceptions: !!cqlResults["Denominator Exceptions"],
      Numerator: !!cqlResults["Numerator"],
    });
  }

  await writer.writeRecords(results);
  console.log(`CSV output written to: ${outputCsv}`);
}

runAllTestCases().catch((e) => {
  console.error("Fatal error:", e);
});

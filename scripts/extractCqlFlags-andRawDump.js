const fs = require("fs");
const path = require("path");
const { Calculator } = require("fqm-execution");
const csvWriter = require("csv-writer").createObjectCsvWriter;

const measureBundlePath = "CMS69-bmi_0.3.000/resources/fqm-bundle.json";
const testCasesDir = "CMS69-bmi_0.3.000/test-cases";
const outputCsv = "cql-flags.csv";
const rawOutputDir = "output/cql-raw";
const valueSetCacheDir = path.resolve("./cache/terminology");

const interestingFlags = [
  "Initial Population",
  "Denominator",
  "Denominator Exclusions",
  "Denominator Exceptions",
  "Numerator"
];

// Ensure output directory exists
fs.mkdirSync(rawOutputDir, { recursive: true });

// Load value set cache
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

    const bundleFiles = fs.readdirSync(fullDirPath).filter(f => f.endsWith(".json"));
    if (bundleFiles.length !== 1) {
      console.warn(`Skipping ${dir}: expected one .json file, found ${bundleFiles.length}`);
      continue;
    }

    const bundlePath = path.join(fullDirPath, bundleFiles[0]);
    const patientBundle = JSON.parse(fs.readFileSync(bundlePath));

    try {
      const raw = await Calculator.calculateRaw(
        measureBundle,
        [patientBundle],
        options,
        valueSetCache
      );

      // Confirm structure
      const resultRoot = raw.results ?? raw;
      let patientId = Object.keys(resultRoot.patientResults || {})[0];
      let resultBlock = resultRoot.patientResults?.[patientId];

      if (!resultBlock || Object.keys(resultBlock).length === 0) {
        patientId = Object.keys(resultRoot.unfilteredResults || {})[0];
        resultBlock = resultRoot.unfilteredResults?.[patientId];

        if (!resultBlock || Object.keys(resultBlock).length === 0) {
          console.warn(`No usable results for: ${dir}`);
          continue;
        }
      }

      // Preview raw result
      const rawString = JSON.stringify(resultBlock, null, 2);
      const lines = rawString.split("\n").slice(0, 20);
      console.log(`\n=== Raw result for test case: ${dir} ===`);
      console.log(lines.join("\n"));

      // Save full raw output to disk
      const outPath = path.join(rawOutputDir, `${patientId}.json`);
      const fullOutput = {
        patientId,
        patientResults: resultRoot.patientResults?.[patientId] ?? null,
        unfilteredResults: resultRoot.unfilteredResults?.[patientId] ?? null
      };
      fs.writeFileSync(outPath, JSON.stringify(fullOutput, null, 2));

      // Save flags to CSV
      const row = { patientId };
      for (const flag of interestingFlags) {
        row[flag.replace(/\s+/g, "")] = resultBlock[flag] === true;
      }
      results.push(row);

    } catch (error) {
      console.warn(`Error processing ${dir}:`, error.message);
    }
  }

  await writer.writeRecords(results);
  console.log(`✅ CSV written to: ${outputCsv}`);
  console.log(`📁 Full raw results saved to: ${rawOutputDir}/`);
}

runAllTestCases().catch((e) => {
  console.error("Fatal error:", e);
});
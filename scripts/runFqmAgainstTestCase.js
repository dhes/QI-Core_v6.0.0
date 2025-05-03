const fs = require("fs");
const path = require("path");
const { Calculator } = require("fqm-execution");

// Load your measure and patient bundles from files
// Update these paths to point to your actual files
const measureBundlePath = "CMS69-bmi_0.3.000/resources/fqm-bundle.json";
const patientBundlePath =
  "CMS69-bmi_0.3.000/new-test-cases/86a542ea-a8de-49e8-be6d-6ca395a571fc/CMS69FHIR-v0.3.000-1110.json";

// Function to load value set cache from the specified location
function loadValueSetCache() {
  const cacheDir = path.resolve("./cache/terminology");
  const valueSetCache = [];

  try {
    if (fs.existsSync(cacheDir)) {
      const files = fs.readdirSync(cacheDir);
      console.log(`Found ${files.length} files in cache directory`);

      files.forEach((file) => {
        if (file.endsWith(".json")) {
          try {
            const content = fs.readFileSync(path.join(cacheDir, file), "utf8");
            valueSetCache.push(JSON.parse(content));
          } catch (err) {
            console.warn(
              `Could not load valueset from file ${file}: ${err.message}`
            );
          }
        }
      });

      console.log(
        `Successfully loaded ${valueSetCache.length} valuesets from cache`
      );
    } else {
      console.log("Cache directory does not exist:", cacheDir);
    }
  } catch (error) {
    console.error("Error loading value set cache:", error);
  }

  return valueSetCache;
}
// Configure calculation options
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

// Run the calculation
async function runCalculation() {
  try {
    // Load measure and patient bundles
    const measureBundle = JSON.parse(fs.readFileSync(measureBundlePath));
    const patientBundle = JSON.parse(fs.readFileSync(patientBundlePath));
    console.log("Successfully loaded bundles from files");

    // Load value set cache from specified location
    const valueSetCache = loadValueSetCache();

    console.log("Starting calculation...");
    // Pass valueSetCache as the fourth parameter
    const { results } = await Calculator.calculateMeasureReports(
      measureBundle,
      [patientBundle],
      options,
      valueSetCache
    );

    // Save results to a file for easier viewing
    fs.writeFileSync(
      "./detailedResults.json",
      JSON.stringify(results, null, 2)
    );
    console.log("Results saved to detailedResults.json");

    // Output basic population results to console
    if (results && results[0] && results[0].detailedResults) {
      console.log("Population results:");
      console.log(
        JSON.stringify(results[0].detailedResults[0].populationResults, null, 2)
      );
    } else {
      console.log("No detailed results found in the calculation output");
    }
  } catch (error) {
    console.error("Error calculating measure:", error);
  }
}

runCalculation();

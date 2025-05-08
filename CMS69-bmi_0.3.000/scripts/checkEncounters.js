const fs = require("fs");
const path = require("path");

const measureDir = path.join(__dirname, "..");  // hardcoded to parent directory of script

const outputDir = path.join(measureDir, "output");
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir);
}
const outputLines = [];

const testCasesDir = path.join(measureDir, "test-cases");
const valueSetPath = path.join(
  measureDir,
  "vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1751.json"
);

if (!fs.existsSync(testCasesDir)) {
  outputLines.push(`No test-cases directory found at ${testCasesDir}`);
  process.exit(1);
}

if (!fs.existsSync(valueSetPath)) {
  outputLines.push(`BMI Encounter ValueSet not found at ${valueSetPath}`);
  process.exit(1);
}

// Load ValueSet and extract codes
const valueSet = JSON.parse(fs.readFileSync(valueSetPath, "utf8"));
const codesFromCompose =
  valueSet.compose?.include?.flatMap((inc) =>
    inc.concept?.map((c) => c.code)
  ) || [];

const codesFromExpansion =
  valueSet.expansion?.contains?.map((c) => c.code) || [];

const validCodes = new Set([...codesFromCompose, ...codesFromExpansion]);

const caseFolders = fs.readdirSync(testCasesDir).filter((f) => {
  const fullPath = path.join(testCasesDir, f);
  return fs.statSync(fullPath).isDirectory();
});

outputLines.push(
  `\nChecking Encounter counts (BMI-eligible only) in test cases for measure: ${measureDir}\n`
);

const measureStart = new Date("2026-01-01T00:00:00.000Z");
const measureEnd = new Date("2026-12-31T23:59:59.999Z");

caseFolders.forEach((folder) => {
  const caseDir = path.join(testCasesDir, folder);
  const files = fs.readdirSync(caseDir).filter((f) => f.endsWith(".json"));

  files.forEach((file) => {
    const filePath = path.join(caseDir, file);
    try {
      const bundle = JSON.parse(fs.readFileSync(filePath, "utf8"));
      const bmiEligibleEncounters = (bundle.entry || [])
        .filter((entry) => entry.resource?.resourceType === "Encounter")
        .filter((enc) => {
          const codings = (enc.resource.type || []).flatMap((t) => t.coding || []);
          const matched = codings.some(
            (coding) =>
              coding.system?.startsWith("http://snomed.info/sct") &&
              validCodes.has(coding.code)
          );
          if (!matched) {
            outputLines.push(
              `⚠️ Encounter ${enc.resource.id || "(no id)"} has codes: ${codings
                .map((c) => `${c.system}|${c.code}`)
                .join(", ")} — none matched`
            );
          }
          return matched;
        })
        .filter((enc) => {
          const start = new Date(enc.resource.period?.start);
          const end = new Date(enc.resource.period?.end);

          const sameDay = start.toISOString().slice(0, 10) === end.toISOString().slice(0, 10);
          const inPeriod = start >= measureStart && end <= measureEnd;
          const statusFinished = enc.resource.status === "finished";
          const notVirtual = enc.resource.class?.code?.toLowerCase() !== "vr";

          if (!sameDay || !inPeriod) {
            outputLines.push(
              `⚠️ Encounter ${enc.resource.id || "(no id)"} failed date check: start=${start.toISOString()}, end=${end.toISOString()}`
            );
          }
          if (!statusFinished) {
            outputLines.push(
              `⚠️ Encounter ${enc.resource.id || "(no id)"} status is not 'finished': status=${enc.resource.status}`
            );
          }
          if (!notVirtual) {
            outputLines.push(
              `⚠️ Encounter ${enc.resource.id || "(no id)"} class is 'virtual': class=${enc.resource.class?.code}`
            );
          }

          return sameDay && inPeriod && statusFinished && notVirtual;
        });

      const patient = (bundle.entry || []).find(
        (entry) => entry.resource?.resourceType === "Patient"
      )?.resource;

      const birthDateStr = patient?.birthDate;
      const birthDate = birthDateStr ? new Date(birthDateStr) : null;

      if (!birthDate) {
        outputLines.push(`⚠️ No birthDate found in Patient resource for ${file}`);
      }

      const eligibleWithAgeCheck = bmiEligibleEncounters.filter(enc => {
        const encounterStart = new Date(enc.resource.period?.start);
        const age = (encounterStart - birthDate) / (365.25 * 24 * 60 * 60 * 1000);
        if (age < 18) {
          outputLines.push(`⚠️ Encounter ${enc.resource.id || "(no id)"} excluded: patient age ${age.toFixed(1)} < 18 at encounter start`);
        }
        return age >= 18;
      });

      const count = eligibleWithAgeCheck.length;
      const status = count === 1 ? "✅" : "❌";
      outputLines.push(`${status} ${file} → BMI-eligible Encounter count: ${count}`);
      if (count > 1) {
        outputLines.push(
          `⚠️ Warning: More than one BMI-eligible Encounter found in ${file}`
        );
      }
    } catch (e) {
      outputLines.push(`❌ Failed to read ${file}: ${e.message}`);
    }
  });
});

fs.writeFileSync(path.join(outputDir, "bmi-encounter-check.txt"), outputLines.join("\n"), "utf8");
console.log(`\nOutput written to ${path.join(outputDir, "bmi-encounter-check.txt")}`);

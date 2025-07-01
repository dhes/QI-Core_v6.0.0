const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");

const TEST_CASES_DIR = path.join(__dirname, "..", "test-cases");
const OUTPUT_FILE = path.join(__dirname, "..","..", "thunder-tests", "collections", "tc_col_CMS349-hiv_0.3.000.json");

const MEASURE_ID = "CMS349FHIRHIVScreening";
const MEASURE_URL = `https://madie.cms.gov/Measure/${MEASURE_ID}`;
const PERIOD_START = "2026-01-01T00:00:00"
const PERIOD_END = "2026-12-31T23:59:59";

function getThunderClientCollection() {
  const colId = uuidv4();
  const folderId = uuidv4();
  const collection = {
    _id: colId,
    colName: "CMS349-hiv_0.3.000",
    created: new Date().toISOString(),
    sortNum: 80000,
    folders: [
      {
        _id: folderId,
        name: "$evaluate-measure",
        containerId: "",
        created: new Date().toISOString(),
        sortNum: 10000,
      },
    ],
    requests: [],
    settings: {
      headers: [{ name: "Content-Type", value: "application/fhir+json" }],
      options: { baseUrl: "{{FHIR_SERVER_URL}}" },
    },
  };

  fs.readdirSync(TEST_CASES_DIR).forEach((uuidDir) => {
    const caseDir = path.join(TEST_CASES_DIR, uuidDir);
    if (!fs.statSync(caseDir).isDirectory()) return;

    const files = fs.readdirSync(caseDir).filter((f) => f.endsWith(".json"));
    if (files.length === 0) return;

    const bundle = JSON.parse(fs.readFileSync(path.join(caseDir, files[0]), "utf8"));
    const entries = bundle.entry || [];

    const report = entries.find(
      (e) =>
        e.resource?.resourceType === "MeasureReport" &&
        e.resource.measure === MEASURE_URL
    )?.resource;

    if (!report) return;

    const patientId = report.contained?.[0]?.parameter?.[0]?.valueString;
    const group = report.group?.[0] || {};
    const popCounts = {};
    for (const pop of group.population || []) {
      const code = pop.code?.coding?.[0]?.code;
      if (code) popCounts[code] = pop.count;
    }

    const measureScore = group.measureScore?.value;

    const reqId = uuidv4();
    collection.requests.push({
      _id: reqId,
      colId: colId,
      containerId: folderId,
      name: patientId,
      url: `Measure/${MEASURE_ID}/$evaluate-measure?subject=Patient/${patientId}&periodStart=${PERIOD_START}&periodEnd=${PERIOD_END}`,
      method: "GET",
      sortNum: 10000,
      created: new Date().toISOString(),
      modified: new Date().toISOString(),
      headers: [],
      params: [
        { name: "subject", value: `Patient/${patientId}`, isPath: false },
        { name: "periodStart", value: PERIOD_START, isPath: false },
        { name: "periodEnd", value: PERIOD_END, isPath: false },
      ],
      tests: [
        {
          type: "res-body",
          custom: "",
          action: "notcontains",
          value: "OperationOutcome",
        },
      ],
      postReq: {
        inlineScripts: [
          {
            script: [
              "let json = tc.response.json;",
              "function getPopCount(code) {",
              "    let pop = json.group[0]?.population.find(p =>",
              "        p.code?.coding?.some(c => c.code === code)",
              "    );",
              "    return pop?.count;",
              "}",
              `tc.test("Initial Population = ${popCounts["initial-population"] ?? 0}", getPopCount("initial-population") === ${popCounts["initial-population"] ?? 0});`,
              `tc.test("Denominator = ${popCounts["denominator"] ?? 0}", getPopCount("denominator") === ${popCounts["denominator"] ?? 0});`,
              `tc.test("Denominator Exclusion = ${popCounts["denominator-exclusion"] ?? 0}", getPopCount("denominator-exclusion") === ${popCounts["denominator-exclusion"] ?? 0});`,
              `tc.test("Numerator = ${popCounts["numerator"] ?? 0}", getPopCount("numerator") === ${popCounts["numerator"] ?? 0});`,
              `tc.test("Measure Score = ${measureScore}", json.group[0]?.measureScore?.value == ${measureScore});`,
            ],
          },
        ],
      },
    });
  });

  return collection;
}

// Ensure output directory exists
fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });

// Write the collection file
const collection = getThunderClientCollection();
fs.writeFileSync(OUTPUT_FILE, JSON.stringify(collection, null, 2), "utf8");

console.log(`✅ ThunderClient collection written to: ${OUTPUT_FILE}`);
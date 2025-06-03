const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");

const TEST_CASES_DIR = path.join(__dirname, "..", "test-cases");
const OUTPUT_FILE = path.join(__dirname, "..", "..", "thunder-tests", "collections", "tc_col_cms138-tobacco_0.2.000_multi.json");

const MEASURE_ID = "CMS138FHIRPreventiveTobaccoCessation";
const MEASURE_URL = `https://madie.cms.gov/Measure/${MEASURE_ID}`;
const PERIOD_START = "2026-01-01T00:00:00";
const PERIOD_END = "2026-12-31T23:59:59";

function getThunderClientCollection() {
  const colId = uuidv4();
  const folderId = uuidv4();
  const collection = {
    _id: colId,
    colName: "CMS138-tobacco_0.2.000",
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
    const reqId = uuidv4();

    // Build a dynamic script for each group
    const testScript = [
      "let json = tc.response.json;",
      "function getPopCount(groupIndex, code) {",
      "    let pop = json.group?.[groupIndex]?.population.find(p =>",
      "        p.code?.coding?.some(c => c.code === code)",
      "    );",
      "    return pop?.count;",
      "}",
      "function getMeasureScore(groupIndex) {",
      "    return json.group?.[groupIndex]?.measureScore?.value;",
      "}",
    ];

    report.group?.forEach((group, index) => {
      const popCounts = {};
      for (const pop of group.population || []) {
        const code = pop.code?.coding?.[0]?.code;
        if (code) popCounts[code] = pop.count;
      }
      const score = group.measureScore?.value;

      for (const [code, count] of Object.entries(popCounts)) {
        testScript.push(`tc.test("Group ${index} - ${code} = ${count}", getPopCount(${index}, "${code}") === ${count});`);
      }
      if (score !== undefined) {
        testScript.push(`tc.test("Group ${index} - Measure Score = ${score}", getMeasureScore(${index}) == ${score});`);
      }
    });

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
          { script: testScript }
        ],
      },
    });
  });

  return collection;
}

fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });

const collection = getThunderClientCollection();
fs.writeFileSync(OUTPUT_FILE, JSON.stringify(collection, null, 2), "utf8");

console.log(`✅ ThunderClient collection written to: ${OUTPUT_FILE}`);
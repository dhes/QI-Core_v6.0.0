require('dotenv').config();
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const readline = require('readline');

const FHIR_BASE = process.env.FHIR_SERVER_URL.replace(/\/$/, '');
const MEASURE_ID = 'CMS69FHIRPCSBMIScreenAndFollowUp';
const PERIOD_START = '2026-01-01';
const PERIOD_END = '2026-12-31';

// console.log(`__dirname: ${__dirname}`);

const inputFile = path.join('CMS69-bmi_0.3.000/notes/all-test-cases-summarized.md');
const outputFile = path.join('CMS69-bmi_0.3.000/notes/all-test-cases-evaluated.md');

const populationMap = {
  'IPP': 'initial-population',
  'DENOM': 'denominator',
  'DENEX': 'denominator-exclusion',
  'DENEXCP': 'denominator-exception',
  'DENEXCEP': 'denominator-exception',
  'DENEXEP': 'denominator-exclusion',
  'NUMER': 'numerator',
};

function extractExpectation(filename) {
  const match = filename.match(/CMS69FHIR-v[0-9.]+-([A-Z]+)(Pass|Fail)-/i);
  if (!match) return [null, null];
  const [_, popCode, status] = match;
  return [popCode.toUpperCase(), status.toLowerCase() === 'pass' ? 1 : 0];
}

function extractPopulationCounts(report) {
  const result = { D: 0, DX: 0, N: 0, DE: 0 };
  const populations = report.group?.[0]?.population || [];
  populations.forEach(p => {
    const code = p.code?.coding?.[0]?.code;
    const count = p.count || 0;
    if (code === 'denominator') result.D = count;
    else if (code === 'denominator-exclusion') result.DX = count;
    else if (code === 'numerator') result.N = count;
    else if (code === 'denominator-exception') result.DE = count;
  });
  return result;
}

async function evaluateMeasure(patientId) {
  const url = `${FHIR_BASE}/Measure/${MEASURE_ID}/$evaluate-measure?subject=Patient/${patientId}&periodStart=${PERIOD_START}&periodEnd=${PERIOD_END}`;
  try {
    const response = await axios.get(url);
    return extractPopulationCounts(response.data);
  } catch (e) {
    console.error(`Error evaluating measure for Patient/${patientId}:`, e.message);
    return { D: 'ERR', DX: 'ERR', N: 'ERR', DE: 'ERR' };
  }
}

async function processFile() {
  const input = fs.createReadStream(inputFile);
  const rl = readline.createInterface({ input });
  const lines = [];
  let isHeader = true;

  for await (const line of rl) {
    lines.push(line);
  }

  const output = [];
  output.push('| Patient ID | File Name | Description | Expected Population Element | Expected Value | D | DX | N | DE |');
  output.push('|------------|-----------|-------------|-----------------------------|----------------|---|----|---|----|');

  for (let i = 1; i < lines.length; i++) {
    const row = lines[i];
    const parts = row.split('|').map(x => x.trim()).filter(Boolean);
    if (parts.length < 2) continue;

    const [patientId, filename, description = ''] = parts;
    const [popCode, expectedValue] = extractExpectation(filename);
    if (!popCode) continue;

    const actualCounts = await evaluateMeasure(patientId);

    output.push(`| ${patientId} | ${filename} | ${description} | ${popCode} | ${expectedValue} | ${actualCounts.D} | ${actualCounts.DX} | ${actualCounts.N} | ${actualCounts.DE} |`);
  }

  fs.writeFileSync(outputFile, output.join('\n'), 'utf-8');
  console.log(`✅ Output written to ${outputFile}`);
}

processFile();
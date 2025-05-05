const fs = require('fs');
const path = require('path');

// Read the report file
const reportPath = path.join(__dirname, '../CMS69-bmi_0.3.000', 'test-case-eval-report.txt');
const reportText = fs.readFileSync(reportPath, 'utf-8');

const lines = reportText.split('\n');
let currentTest = '';
const mismatches = [];

lines.forEach((line) => {
  if (line.startsWith('✅') || line.startsWith('❌')) {
    currentTest = line.trim();
  } else if (line.includes('initial-population=')) {
    const parts = Object.fromEntries(
      line
        .trim()
        .split(',')
        .map(p => p.trim().split('=').map(x => x.trim()))
    );

    const ip = parseInt(parts['initial-population'] || '0', 10);
    const denom = parseInt(parts['denominator'] || '0', 10);
    const denex = parseInt(parts['denominator-exclusion'] || '0', 10);
    const numer = parseInt(parts['numerator'] || '0', 10);
    const denexcep = parseInt(parts['denominator-exception'] || '0', 10);
    const msRaw = parts['measureScore'] || '—';

    const ms = msRaw === '—' ? null : parseFloat(msRaw);
    const base = denom - denex - denexcep;
    const expected = base > 0 ? numer / base : null;

    const mismatch =
      expected !== null &&
      ms !== null &&
      Math.abs(ms - expected) > 0.0001;

    if (mismatch) {
      mismatches.push({
        testCase: currentTest,
        measureScore: ms,
        expectedScore: parseFloat(expected.toFixed(2)),
        ip, denom, denex, numer, denexcep
      });
    }
  }
});

console.log(`Found ${mismatches.length} mismatches:\n`);
mismatches.forEach(m => {
  console.log(`❌ ${m.testCase}`);
  console.log(`   measureScore=${m.measureScore} but expected=${m.expectedScore}`);
  console.log(`   IP=${m.ip}, DENOM=${m.denom}, DENEX=${m.denex}, NUMER=${m.numer}, DENEXCEP=${m.denexcep}`);
  console.log();
});
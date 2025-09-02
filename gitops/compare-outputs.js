const [,, baselinePath, pdPath] = process.argv;
const baseline = require(baselinePath);
const pd = require(pdPath);

// TODO: implement deep comparison
console.log(`Comparing ${baselinePath} with ${pdPath}`);
console.log(`(Stub) IP count: baseline=${baseline.results.length}, pd=${pd.results.length}`);
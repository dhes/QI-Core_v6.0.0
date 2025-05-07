## Steps

- deploy measure-specific resolvers bundle via ThunderClient
- scan cql, identify valueset and download valueset to vocabulary/valueset/external using
```
node scripts/downloadVSACWithPuppeteer.js --measure-dir={measureDir}
```
- deploy ValueSets to HAPI
```
node scripts/deployValueSetsToHAPI.js --measure-dir={measureDir}
```
- deploy Measure and Library resource e.g. (2 methods)
  - script (preferred)
```
node scripts/deployResourcesToHAPI.js --measure-dir {measureDir}
```
  - API call POST as-is resource bundle

- deploy test cases
```
node scripts/deployTestCases.js --measure-dir {measureDir}
```
  - if you are performing this step for the first time with a new measure, you may have to cycle through some errors to build a new resolver.json bundle. 

- maybe reboot server ;)
- (obsolete) gather ID of Measure if you used API call POST as-is resource bundle
```
GET Measure
```
- edit $evaluate-measure call with ID
```
Measure/{measureId}/$evaluate-measure?subject=Patient/5d34e56e-f4f1-4817-b7e4-e4c57f811300&periodStart=2026-01-01&periodEnd=2026-12-31
```
- upload any new common libraries with `safeLoadCommonLibraries.js`

## Gotcha!

If you are revising CQL libraries and you have to use version to cross-reference a Measure and a Library
- HAPI can resolve Measure.library like 
```
[
  "https://madie.cms.gov/Library/CMS69FHIRPCSBMIScreenAndFollowUp|0.3.001"
]
```
- RefreshIG *cannot*. It literally compares the string inside the array to the Library.url. It will not resolve the version. 

That means if you are planning different version of a library on one server and you will be revising CQL, you will have to
- remove the |{version} from Measure.library
- run RefreshIG
- put it back in its input/measure version and its bundle/measure version. 

## Finally

Once everything is uploaded and ready to go, run `runEvaluateMeasureActualOnly.js` e.g.
```
node scripts/runEvaluateMeasureActualOnly.js --measure-dir=CMS69-bmi_0.3.000 --measure-id=CMS69FHIRPCSBMIScreenAndFollowUp
```
That will report all population counts as well as measureScore per HAPI, and compare it with our own measureScore calculation
```
      const MS = res.data.group?.[0]?.measureScore?.value ?? null;
      const TD = counts.D === 1 && counts.DX === 0 && counts.DE === 0;
      const TN = TD && counts.N === 1 && counts.NX === 0;
      const eMS = TD ? (TN ? 1.0 : 0.0) : null;

```
Beautiful and concise, no?

Review the outputs of that routine in {measure-dir}/actual-eval-report.csv and {measure-dir}/actual-eval-report.txt. If it look good you can move on to the next Measure. 




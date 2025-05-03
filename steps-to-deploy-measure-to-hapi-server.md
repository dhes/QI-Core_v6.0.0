## Steps

- deploy resolvers bundle via ThunderClient
- deploy ValueSets via scripts/deployValueSetsToHAPI.js
```
node scripts/deployValueSetsToHAPI.js
```
- deploy Measure and Library resource e.g. (2 methods)
1) script
```
node scripts/deployResourcesToHAPI.js --measure-dir CMS69-bmi_0.3.000
```
2) API call POST as-is resource bundle
- deploy test cases
```
node scripts/deployTestCases.js --measure-dir CMS69-bmi_0.3.000
```
- maybe reboot server ;)
- gather ID of Measure if you used API call POST as-is resource bundle
```
GET Measure
```
- edit $evaluate-measure call with ID
```
Measure/{measureId}/$evaluate-measure?subject=Patient/5d34e56e-f4f1-4817-b7e4-e4c57f811300&periodStart=2026-01-01&periodEnd=2026-12-31
```

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


# Troubleshooting CMS69-bmi mismatch between file name Pass/Fail and actual result
## Select a MeasureReport from a test case bundle
All mismatches are in the DX population filters. For details please refer to this [spreadsheet](CMS69-bmi_0.3.000/notes/all-test-cases-evaluated.numbers)
```
jq '.entry[] 
  | select(.resource.resourceType == "MeasureReport") 
  | .resource.extension[]
  | select(.url == "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-testCaseDescription")
  | .valueMarkdown
' {relativePath}
```
Examine resources in bundle
```
jq '.entry[].resource.resourceType
' {}
```
Open a Condition

```
jq '.entry[] 
  | select(.resource.resourceType == "Condition") 
'
```
Take note of 
```
"onsetDateTime": "2026-01-01T00:30:00.000+00:00"
```
and 
```
"code": {
      "coding": [
        {
          "system": "http://snomed.info/sct",
          "version": "2022-03",
          "code": "441874000",
          "display": "Seen by palliative care service (finding)",
          "userSelected": true
        }
      ]
    },
```
The Condition date seems to overlap the MP. The code should be in the proper valueset. 
```
jq '.expansion.contains[] | select(.code == "441874000")
' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.1167.json
```
The codes but not the version match. We'll try updating the Condition on the server to exclude the version. Here's is the updated version. 
```
{
        "resourceType": "Condition",
        "id": "28c0b633-0691-4a48-8349-ab80e2f438d1",
        "meta": {
          "versionId": "1",
          "lastUpdated": "2025-05-03T14:33:39.372-10:00",
          "source": "#nnxAqY6t4So8NyWi",
          "profile": [
            "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns"
          ]
        },
        "clinicalStatus": {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
              "code": "active",
              "display": "active",
              "userSelected": true
            }
          ]
        },
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                "code": "problem-list-item",
                "display": "Problem List Item"
              },
              {
                "system": "http://snomed.info/sct",
                "code": "441874000",
                "display": "Diagnosis"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "441874000",
              "display": "Seen by palliative care service (finding)",
              "userSelected": true
            }
          ]
        },
        "subject": {
          "reference": "Patient/5d48c3b8-93e9-4e29-8c20-a002761d9e24"
        },
        "onsetDateTime": "2026-01-01T00:30:00.000+00:00"
      }
```
That change did not result in DX = 1. Try removing userSelected. 
```
{
        "resourceType": "Condition",
        "id": "28c0b633-0691-4a48-8349-ab80e2f438d1",
        "meta": {
          "versionId": "1",
          "lastUpdated": "2025-05-03T14:33:39.372-10:00",
          "source": "#nnxAqY6t4So8NyWi",
          "profile": [
            "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns"
          ]
        },
        "clinicalStatus": {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
              "code": "active",
              "display": "active",
              "userSelected": true
            }
          ]
        },
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                "code": "problem-list-item",
                "display": "Problem List Item"
              },
              {
                "system": "http://snomed.info/sct",
                "code": "441874000",
                "display": "Diagnosis"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "441874000",
              "display": "Seen by palliative care service (finding)"
            }
          ]
        },
        "subject": {
          "reference": "Patient/5d48c3b8-93e9-4e29-8c20-a002761d9e24"
        },
        "onsetDateTime": "2026-01-01T00:30:00.000+00:00"
      }
```
DX still = 0. 

Try remove the extraneous category code. 
```
{
        "resourceType": "Condition",
        "id": "28c0b633-0691-4a48-8349-ab80e2f438d1",
        "meta": {
          "versionId": "1",
          "lastUpdated": "2025-05-03T14:33:39.372-10:00",
          "source": "#nnxAqY6t4So8NyWi",
          "profile": [
            "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns"
          ]
        },
        "clinicalStatus": {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
              "code": "active",
              "display": "active",
              "userSelected": true
            }
          ]
        },
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                "code": "problem-list-item",
                "display": "Problem List Item"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "441874000",
              "display": "Seen by palliative care service (finding)"
            }
          ]
        },
        "subject": {
          "reference": "Patient/5d48c3b8-93e9-4e29-8c20-a002761d9e24"
        },
        "onsetDateTime": "2026-01-01T00:30:00.000+00:00"
      }
```
Still zero. 

That does not seem to be the problem. It may be the old 'union problem'. Looking at this snippet of the PalliativeCare identifier "Has Palliative Care in the Measurement Period"

```
exists ((([ConditionProblemsHealthConcerns: "Palliative Care Diagnosis"])
    union ([ConditionEncounterDiagnosis: "Palliative Care Diagnosis"])) PalliativeDiagnosis
        where PalliativeDiagnosis.prevalenceInterval() overlaps day of "Measurement Period"
    )
```
...this clause might always return null (on some servers) because ConditionProblemsHealthConcerns and ConditionEncounterDiagnosis may be treated as different. It's interesting that this pattern also occurs in the Hospice library

```
exists ((([ConditionProblemsHealthConcerns: "Hospice Diagnosis"])
        union ([ConditionEncounterDiagnosis: "Hospice Diagnosis"])) HospiceCareDiagnosis
        where HospiceCareDiagnosis.prevalenceInterval() overlaps day of "Measurement Period")
```

the pregnancy identifier

```
define "Is Pregnant During Day Of Measurement Period":
  ( [ConditionProblemsHealthConcerns: "Pregnancy or Other Related Diagnoses"]
    union [ConditionEncounterDiagnosis: "Pregnancy or Other Related Diagnoses"] ) PregnancyDiagnosis
```
which might account for all of the mismatches. It look like all of the cases involve Condition or Encounter diagnoses. That's pretty good circumstantial evidence. 

This might work: 

```
{
      "resourceType": "Condition",
      "id": "28c0b633-0691-4a48-8349-ab80e2f438d1",
      "meta": {
        "profile": [ "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-problems-health-concerns",
                     "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-condition-encounter-diagnosis"
       ]
      },
      "clinicalStatus": {
        "coding": [ {
          "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
          "code": "active",
          "display": "active",
          "userSelected": true
        } ]
      },
      "category": [ {
        "coding": [ {
          "system": "http://terminology.hl7.org/CodeSystem/condition-category",
          "code": "problem-list-item",
          "display": "Problem List Item"
        }, {
          "system": "http://snomed.info/sct",
          "code": "441874000",
          "display": "Diagnosis"
        } ]
      } ],
      "code": {
        "coding": [ {
          "system": "http://snomed.info/sct",
          "version": "2022-03",
          "code": "441874000",
          "display": "Seen by palliative care service (finding)",
          "userSelected": true
        } ]
      },
      "subject": {
        "reference": "Patient/5d48c3b8-93e9-4e29-8c20-a002761d9e24"
      },
      "onsetDateTime": "2026-01-01T00:30:00.000+00:00"
    }
```
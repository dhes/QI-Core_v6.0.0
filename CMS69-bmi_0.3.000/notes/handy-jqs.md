```
jq '.entry[] | select(.resource.resourceType == "Patient") | .resource.birthDate' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
"2006-01-31"
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.period' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
{
  "start": "2026-01-01T08:00:00.000+00:00",
  "end": "2026-01-01T08:30:00.000+00:00"
}
20 yo on date of encounter
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
{
  "system": "http://snomed.info/sct",
  "version": "2022-03",
  "code": "185465003",
  "display": "Weekend visit (procedure)",
  "userSelected": true
}
snomed|185465003
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
Encounter.type.code 185465003
Encounter qualifies. 
IP = true, D = true
```
jq '.expansion.contains[] | select(.code == "185465003")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1751.json
```
ValueSet .1751 contains 185465003

#### Find a BMI observation
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "139156-5"))
  | .resource
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
no such.
#### sample positive test case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "139156-5"))
  | .resource
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
OK, that returns a file name if the BMI observation is present in the bundle. How about we display the code for all Observations in the bundle. 

#### display the code of all Observations in the bundle. 
##### positive case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
##### negative case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
OK - so in any case 0278fdf0 has no BMI, so D = 1, N = 0. Any DE or DX?

## Palliative Care
### Observation Case
Reuse 'display the code of all Observations in the bundle.' from above. Do you see `'71007-9' from "LOINC"`?
Check the date
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | .resource.effectiveDateTime
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
### Condition Case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
If present, check it in the corresponding valueset
```
jq '.expansion.contains[] | select(.code == "12345678")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.1167.json
```
and then the dates
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.onsetDateTime
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.abatementDateTime
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
##### Positive Test Case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
If present, check it in the corresponding valueset
```
jq '.expansion.contains[] | select(.code == "162863004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.1167.json
```
(It's not a palliative care code, so it won't be there)
and then the dates
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.onsetDateTime
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.abatementDateTime
' CMS69-bmi_0.3.000/test-cases/1ba2fc33-1a1b-416b-bb3c-79ba5d0d3359/CMS69FHIR-v0.3.000-NUMERFail-HighBMIAndInterventionOrderedFollowUpConditionEndsB4InterventionOrder.json
```
### Encounter Case
Use previous encounter jq => snomed|185465003

Is that in valueset 2.16.840.1.113883.3.464.1003.101.12.1090.json?
```
jq '.expansion.contains[] | select(.code == "185465003")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.101.12.1090.json
```
And we already know the date of the Encounter from the previous query. 
```
jq '.expansion.contains[] | select(.code == "185465003")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.101.12.1090.json
```
### Procedure Case
Is procedure present?
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.code' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
positive test case
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.code' CMS69-bmi_0.3.000/test-cases/09e4ff5a-fe3b-4c89-a36e-68f64c7e489c/CMS69FHIR-v0.3.000-DENEXPass-PalliativeCareProcedureFirstDayOfMP.json
```
and the date 'performedDateTime', if the resource is present
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.performedDateTime' CMS69-bmi_0.3.000/test-cases/09e4ff5a-fe3b-4c89-a36e-68f64c7e489c/CMS69FHIR-v0.3.000-DENEXPass-PalliativeCareProcedureFirstDayOfMP.json
```

## Hospice
### Inpatient Encounter
An Encounter filtered by ValueSet .307, involving Encounter.period, Encounter.dischargeDisposition (2 possible snomed codes). Our current case is a negative test case. 

#### Resource filter

```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
Result: Code SNOMEDCT|185465003

#### ValueSet filter
```
jq '.expansion.contains[] | select(.code == "185465003")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.666.5.307.json
```
(nothing)
##### Positive Test Case

Resource
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/57858042-c2aa-49f4-b401-1f1fd9ab289a/CMS69FHIR-v0.3.000-DENEXPass-DischargeToHomeHospiceCareDuringMP.json
```
returns
```
{
  "system": "http://snomed.info/sct",
  "version": "2022-03",
  "code": "10197000",
  "display": "Psychiatric interview and evaluation (procedure)",
  "userSelected": true
}
{
  "system": "http://snomed.info/sct",
  "version": "2022-03",
  "code": "183452005",
  "display": "Emergency hospital admission (procedure)",
  "userSelected": true
}
```
ValueSet
```
jq '.expansion.contains[] | select(.code == "183452005")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.666.5.307.json
```
returns
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "183452005",
  "display": "Emergency hospital admission (procedure)"
}
```
#### period ends during Measurement Period
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.period.end' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
#### discharge disposition equals code #1

'428361000124107' from "SNOMEDCT" or '428371000124100' from "SNOMEDCT"
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.hospitalization.dischargeDisposition' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
##### Positive Test Case
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.hospitalization.dischargeDisposition' CMS69-bmi_0.3.000/test-cases/57858042-c2aa-49f4-b401-1f1fd9ab289a/CMS69FHIR-v0.3.000-DENEXPass-DischargeToHomeHospiceCareDuringMP.json
```
returns
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "code": "428361000124107",
      "display": "Discharge to home for hospice care (procedure)",
      "userSelected": true
    }
  ]
}
```
### Hospice Encounter
valueSet 2.16.840.1.113883.3.464.1003.1003
Resource Filter
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
Result: Code SNOMEDCT|185465003

#### ValueSet filter
```
jq '.expansion.contains[] | select(.code == "185465003")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.1003.json
```
(nothing)
##### Positive test case
45b1ce40-0f49-4559-8c3b-5c2a8070b0a7/CMS69FHIR-v0.3.000-DENEXPass-HospiceEncounter.json
Resource Filter
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.type[0].coding[0]' CMS69-bmi_0.3.000/test-cases/45b1ce40-0f49-4559-8c3b-5c2a8070b0a7/CMS69FHIR-v0.3.000-DENEXPass-HospiceEncounter.json
```
result
```
{
  "system": "http://snomed.info/sct",
  "version": "2022-03",
  "code": "305336008",
  "display": "Admission to hospice (procedure)",
  "userSelected": true
}
```
valueset search
```
jq '.expansion.contains[] | select(.code == "305336008")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.464.1003.1003.json
```
returns
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "305336008",
  "display": "Admission to hospice (procedure)"
}

#### date filter
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.period' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
day of which should overlap Measurement period. 
Returns 
```
{
  "start": "2026-01-01T08:00:00.000+00:00",
  "end": "2026-01-01T08:30:00.000+00:00"
}
```
### Observation
code "Hospice care [Minimum Data Set]": '45755-6' from from "LOINC"
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "45755-6"))
  | .resource
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
returns nothing. 
#### Positive Test Case
736b5472-4a6f-4278-80d3-373d1c78c4c5/CMS69FHIR-v0.3.000-DENEXPass-HospiceObservationAssessment.json
system:
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "45755-6"))
  | .resource.code.coding[0].system
' CMS69-bmi_0.3.000/test-cases/736b5472-4a6f-4278-80d3-373d1c78c4c5/CMS69FHIR-v0.3.000-DENEXPass-HospiceObservationAssessment.json
```
returns "http://loinc.org"
code:
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "45755-6"))
  | .resource.code.coding[0].code
' CMS69-bmi_0.3.000/test-cases/736b5472-4a6f-4278-80d3-373d1c78c4c5/CMS69FHIR-v0.3.000-DENEXPass-HospiceObservationAssessment.json
returns "45755-6"
```

### ServiceRequest
resource filter valueset .1584 
time filter .authoredOn during MP
This one actually applies to our patient. 
Here's the time element
```
jq '.entry[] | select(.resource.resourceType == "ServiceRequest") | .resource.authoredOn' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
returns "2026-01-01T08:01:00.000+00:00". 
And the code element
```
jq '.entry[] | select(.resource.resourceType == "ServiceRequest") | .resource.code' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
returns
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "version": "2022-03",
      "code": "386292004",
      "display": "Exercise promotion: stretching (procedure)",
      "userSelected": true
    }
  ]
}
```
#### valueset search
```
jq '.expansion.contains[] | select(.code == "386292004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1584.json
```
no match
#### Positive Test Case

1b102c21-830a-41a5-ac27-9aa77ea5adfe/CMS69FHIR-v0.3.000-DENEXPass-HospicePerformedDuringMP
resource query
```
jq '.entry[] | select(.resource.resourceType == "ServiceRequest") | .resource.code' CMS69-bmi_0.3.000/test-cases/1b102c21-830a-41a5-ac27-9aa77ea5adfe/CMS69FHIR-v0.3.000-DENEXPass-HospicePerformedDuringMP.json
```
return
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "version": "2022-03",
      "code": "385763009",
      "display": "Hospice care (regime/therapy)",
      "userSelected": true
    }
  ]
}
```
ValueSet Query
```
jq '.expansion.contains[] | select(.code == "385763009")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1584.json
```
Returns
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "385763009",
  "display": "Hospice care (regime/therapy)"
}
```
### Procedure
resource filter valueset .1584 (same as previous)
Time - performed during MP
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.code' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
returns nothing. 
timing
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.performed' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
of course also returns nothing. 
#### Positive Test Case
1b102c21-830a-41a5-ac27-9aa77ea5adfe/CMS69FHIR-v0.3.000-DENEXPass-HospicePerformedDuringMP
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.performedDateTime' CMS69-bmi_0.3.000/test-cases/1b102c21-830a-41a5-ac27-9aa77ea5adfe/CMS69FHIR-v0.3.000-DENEXPass-HospicePerformedDuringMP.json
```
returns "2026-12-31T20:00:00.000+00:00"
```
jq '.entry[] | select(.resource.resourceType == "Procedure") | .resource.code' CMS69-bmi_0.3.000/test-cases/1b102c21-830a-41a5-ac27-9aa77ea5adfe/CMS69FHIR-v0.3.000-DENEXPass-HospicePerformedDuringMP.json
```
returns
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "version": "2022-03",
      "code": "170935008",
      "display": "Full care by hospice (finding)",
      "userSelected": true
    }
  ]
}
```
and ValueSet query
```
jq '.expansion.contains[] | select(.code == "170935008")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1584.json
```
returns
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "170935008",
  "display": "Full care by hospice (finding)"
}

### Condition
valueSet "Hospice Diagnosis" 2.16.840.1.113883.3.464.1003.1165

```
jq '.entry[] | select(.resource.resourceType == "Condition") | .resource.code' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
There's no Condition resource in our index case, so of course it returns nothing. 

### Positive Test Case
there are two, one for problem-list-diagnosis (matching ConditionProblemsHealthConcerns) and encounter-diagnosis (matching ConditionEncounterDiagnosis). In order:
- 5ef4acf3-4b42-41fd-8793-7d1a9342865a/CMS69FHIR-v0.3.000-DENEXPass-HospiceCondition.json
- ca6deaeb-459d-4d1a-9daf-e454ff76a6f0/CMS69FHIR-v0.3.000-DENEXPass-HospiceCondition-67f6d67ebdc50b65bdb89c70

We'll do the first. 
```
jq '.entry[] | select(.resource.resourceType == "Condition") | .resource.code' CMS69-bmi_0.3.000/test-cases/5ef4acf3-4b42-41fd-8793-7d1a9342865a/CMS69FHIR-v0.3.000-DENEXPass-HospiceCondition.json
```
returns
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "version": "2022-03",
      "code": "170936009",
      "display": "Shared care - hospice and general practitioner (finding)",
      "userSelected": true
    }
  ]
}
```
ValueSet query
```
jq '.expansion.contains[] | select(.code == "170936009")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1584.json
```
returns 
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "170936009",
  "display": "Shared care - hospice and general practitioner (finding)"
}
```
and that's a match. 

So much for Hospice. On to Pregnancy. 


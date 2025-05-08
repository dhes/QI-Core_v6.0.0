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
  | select(.system == "http://loinc.org" and .code == "39156-5"))
  | .resourcev.alueQuantity
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
no such.
#### sample positive test case
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "39156-5"))
  | .resource.valueQuantity
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

## Pregnancy
ValueSet 2.16.840.1.113883.3.600.1.1623
timing prevalenceInterval overlaps MP
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
The index patient has no Condition resource. 

### Positive Test Case

d318f512-656e-43bf-a409-16b6e24462a9/CMS69FHIR-v0.3.000-DENEXPass-PregnancyOnsetFirstDayOfMP.json

```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/d318f512-656e-43bf-a409-16b6e24462a9/CMS69FHIR-v0.3.000-DENEXPass-PregnancyOnsetFirstDayOfMP.json
```
returns
```
{
  "coding": [
    {
      "system": "http://snomed.info/sct",
      "version": "2022-03",
      "code": "10231000132102",
      "display": "In-vitro fertilization pregnancy (finding)",
      "userSelected": true
    }
  ]
}
```
and 
```
jq '.expansion.contains[] | select(.code == "10231000132102")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1623.json
```
returns
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "10231000132102",
  "display": "In-vitro fertilization pregnancy (finding)"
}
```
Now for the prevalenceInterval. 
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.onsetDateTime
' CMS69-bmi_0.3.000/test-cases/d318f512-656e-43bf-a409-16b6e24462a9/CMS69FHIR-v0.3.000-DENEXPass-PregnancyOnsetFirstDayOfMP.json
```
and
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Condition") 
  | .resource.abatementDateTime
' CMS69-bmi_0.3.000/test-cases/d318f512-656e-43bf-a409-16b6e24462a9/CMS69FHIR-v0.3.000-DENEXPass-PregnancyOnsetFirstDayOfMP.json
```
That's it for Exclusions now for 
# Exceptions
## "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI"
### ServiceRequest: [ServiceNotRequested: "Referrals Where Weight Assessment May Occur"]
valueSet 2.16.840.1.113883.3.600.1.1525,2.16.840.1.113883.3.600.1.1527,2.16.840.1.113883.3.600.1.1527
```
jq '
  .entry[] 
  | select(.resource.resourceType == "ServiceRequest") 
  | .resource.code
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
Our index patient does have a ServiceRequest, so we get
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
so we'll look for the code in the valuesets. There are actually three, due to unions in the CQL statement. Any one will satisfy. We'll do all three
```
jq '.expansion.contains[] | select(.code == "386292004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1525.json
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "386292004",
  "display": "Exercise promotion: stretching (procedure)"
}
```
jq '.expansion.contains[] | select(.code == "386292004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1527.json
```
null
```
jq '.expansion.contains[] | select(.code == "386292004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1528.json
```
and something. 
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "386292004",
  "display": "Exercise promotion: stretching (procedure)"
}
```
showing that valueset may sometimes intersect. Not done yet. Because of the line
```
...
      with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
        such that NoBMIFollowUp.authoredOn same day as start of QualifyingEncounter.period
...
```
we have to compare the day of the serviceRequest vs the day of the Encounter. Here's the encounter again
```
jq '.entry[] | select(.resource.resourceType == "Encounter") | .resource.period' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
=
```
{
  "start": "2026-01-01T08:00:00.000+00:00",
  "end": "2026-01-01T08:30:00.000+00:00"
}
```
So now for the SR.authoredOn
```
jq '.entry[] | select(.resource.resourceType == "ServiceRequest") | .resource.authoredOn' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
"2026-01-01T08:01:00.000+00:00"
Is the authored on the same day as the start of the encounter? I think so! So we're past that hurdle.

Two more filters
```
NoBMIFollowUp.status ~ 'completed'
```
We'll test with 
```
jq '.entry[] | select(.resource.resourceType == "ServiceRequest") | .resource.status' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
```
"completed"
```
and 
```
NoBMIFollowUp.reasonRefused in "Medical Reason"
```
"Medical Reason" valueset is 2.16.840.1.113883.3.526.3.1007, so let's check, using this time the value of the extension valueCodeableConcept. First we have to extract that code 
```
jq '
  .entry[]
  | select(.resource.resourceType == "ServiceRequest")
  | .resource.extension[]
  | select(.url == "http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-doNotPerformReason")
  | .valueCodeableConcept.coding[]
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
returning
```
{
  "system": "http://snomed.info/sct",
  "code": "407563006",
  "display": "Treatment not tolerated (situation)",
  "userSelected": true
}
```

```
jq '.expansion.contains[] | select(.code == "407563006")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1007.json
```
=>
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "407563006",
  "display": "Treatment not tolerated (situation)"
}
```
So it looks like this patient has DE=1!

Now of course we're are done with this case, but not yet with the logic. 
### MedicationNotRequested
```
define "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI":
    ...already done...
    union ( ( [MedicationNotRequested: "Medications for Above Normal BMI"]
        union [MedicationNotRequested: "Medications for Below Normal BMI"] ) NoBMIFollowUp
        with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
          such that NoBMIFollowUp.authoredOn same day as start of QualifyingEncounter.period
        where NoBMIFollowUp.status ~ 'completed'
          // TODO: https://oncprojectracking.healthit.gov/support/projects/MADIE/issues/MADIE-2124
          // Expecting 4 failures until this translator issue is incorporated into MADiE
          
          
          and NoBMIFollowUp.reasonCode in "Medical Reason"
    )
```
This runs parallel to the ServicNotRequested style resource. 
The valuesets are 
- "Medications for Above Normal BMI": 2.16.840.1.113883.3.526.3.1561
- "Medications for Below Normal BMI": 2.16.840.1.113883.3.526.3.1562

So we test for a MedicationRequest resource. 
```
jq '.entry[] | select(.resource.resourceType == "MedicationRequest") | .resource.medicationCodeableConcept' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
which is null. This patient has no MedicationRequest resource. 

#### Positive test case
050201c2-c2c4-46e6-8288-a34f99caebdc/050201c2-c2c4-46e6-8288-a34f99caebdc.json
Resource code
```
jq '
  .entry[]
  | select(.resource.resourceType == "MedicationRequest")
  | .resource.medicationCodeableConcept.coding[]
' CMS69-bmi_0.3.000/test-cases/050201c2-c2c4-46e6-8288-a34f99caebdc/050201c2-c2c4-46e6-8288-a34f99caebdc.json
```
```
{
  "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
  "code": "1112982",
  "display": "phentermine hydrochloride 15 MG Disintegrating Oral Tablet",
  "userSelected": true
}
```
Now to look into the valueset 2.16.840.1.113883.3.526.3.1561
```
jq '.expansion.contains[] | select(.code == "1112982")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1561.json
```
yielding
```
{
  "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
  "version": "03032025",
  "code": "1112982",
  "display": "phentermine hydrochloride 15 MG Disintegrating Oral Tablet"
}
```
So we know this jq works. 

I'm going to skip over "Medications for Below Normal BMI". We've tested similar logic for the rest of this CQL identifier, so we'll move on. 

## "Medical Reason Or Patient Reason For Not Performing BMI Exam"
This is the second part of "Denominator Exceptions". This is a step backward in the sequence of event. Now we are addressing missing BMIs, now lack of action like in the previous section. Here's the full CQL definition
```
define "Medical Reason Or Patient Reason For Not Performing BMI Exam":
  [ObservationCancelled: code = "Body mass index (BMI) [Ratio]"] NoBMI
    with "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
      such that NoBMI.effective.toInterval ( ) ends same day as start of QualifyingEncounter.period
    where NoBMI.status = 'cancelled'
      and ( NoBMI.notDoneReason in "Patient Declined"
          or NoBMI.notDoneReason in "Medical Reason"
      )
```
# Back to the Numerator

We have two targets to meet to make Medicare happy. It's not enough to measure the BMI. No! You must do something about it. First remember -- if you don't have a denominator, there is no numerator. Fahgeddaboudit. 

Here is the CQL "Numerator" identifier, entire. 
```
define "Numerator":
  exists "High BMI And Follow Up Provided"
    or exists "Low BMI And Follow Up Provided"
    or "Has Normal BMI"
```
We've already checked for a BMI Observation resource. Now we have to examine its value. 

## Normal BMI?

Recall the BMI Observation query. 
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "39156-5"))
  | .resource.valueQuantity
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
In our test case this return nothing, because Poor Patient didn't get their BMI recorded. Let's pick a positive test case. 

### Positive Test Case
42e6b4d6-defc-4ec5-894f-e3333e3039a3/CMS69FHIR-v0.3.000-NUMERPass-NormalBMIAt24pt9

#### Just Right
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "39156-5"))
  | .resource.valueQuantity
' CMS69-bmi_0.3.000/test-cases/42e6b4d6-defc-4ec5-894f-e3333e3039a3/CMS69FHIR-v0.3.000-NUMERPass-NormalBMIAt24pt9.json
```
returns
```
{
  "value": 24.9,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```
Now we have a number to work with. Here is the definition of 'normal' from the CQL.
```
 "BMI During Measurement Period" BMI
      where BMI.value >= 18.5 'kg/m2'
        and BMI.value < 25 'kg/m2'
```
So our value of 24.9 passes as normal. In the case of this test patient, the Measure has been satisfied. 

#### Too much

Now for a test case that is positive on the first requirement (BMI recorded) but unknown on the second (BMI abnormal, anything done.) Let's find a case where the BMI is too high. 
```
260e1fc8-227f-4c16-bfc6-22625380a12c/CMS69FHIR-v0.3.000-DENEXCEPPass-MedicalReasonNoFollowupPlanHighBMI
```
Grab the value
```
jq '
  .entry[] 
  | select(.resource.resourceType == "Observation") 
  | select(.resource.code.coding[]? 
  | select(.system == "http://loinc.org" and .code == "39156-5"))
  | .resource.valueQuantity
' CMS69-bmi_0.3.000/test-cases/260e1fc8-227f-4c16-bfc6-22625380a12c/CMS69FHIR-v0.3.000-DENEXCEPPass-MedicalReasonNoFollowupPlanHighBMI.json
```
result
```
{
  "value": 30,
  "unit": "kg/m2",
  "system": "http://unitsofmeasure.org",
  "code": "kg/m2"
}
```
Too high! 'Cha gonna do about it? Here's the clue. 
```cql
  "Documented High BMI During Measurement Period" HighBMI
    with ( "High BMI Interventions Ordered"
      union "High BMI Interventions Performed" ) HighBMIInterventions
```
If you want to win the prize, you have to order an Intervention or perform one. Let's drill down on the first. Brace yourself. 
```cql
define "High BMI Interventions Ordered":
  ( ( [ServiceRequest: "Follow Up for Above Normal BMI"]
      union [ServiceRequest: "Referrals Where Weight Assessment May Occur"]
      union [MedicationRequest: "Medications for Above Normal BMI"] ) HighInterventionsOrdered
      where HighInterventionsOrdered.reasonCode in "Overweight or Obese"
        or ( exists [ConditionProblemsHealthConcerns: "Overweight or Obese"] OverweightObese
            where ( OverweightObese.isProblemListItem ( )
                or OverweightObese.isHealthConcern ( )
            )
              and OverweightObese.isActive ( )
              and OverweightObese.prevalenceInterval ( ) starts before or on day of HighInterventionsOrdered.authoredOn
        )
  )
```
There's a lot here. The good news is that you have lots of options. But it looks complicated. Basically you have a make a ServiceRequest or MedicationRequest AND it has to be paired with a Condition resource that is properly coded, active and starts on or before the day of the order. It's all pretty detailed. 
Let's first look at the ValueSets

|resource|identifier|valueSet|
|---|---|---|
|ServiceRequest|"Follow Up for Above Normal BMI"|2.16.840.1.113883.3.600.1.1525|
|ServiceRequest|"Referrals Where Weight Assessment May Occur"|2.16.840.1.113883.3.600.1.1527|
|MedicationRequest|"Medications for Above Normal BMI"|2.16.840.1.113883.3.526.3.1561|

Let's look at the resources in this positive test case. In the first case
```
jq '
  .entry[]
  | select(.resource.resourceType == "ServiceRequest")
  | .resource.code[]
' CMS69-bmi_0.3.000/test-cases/260e1fc8-227f-4c16-bfc6-22625380a12c/CMS69FHIR-v0.3.000-DENEXCEPPass-MedicalReasonNoFollowupPlanHighBMI.json
```
returns
```
[
  {
    "system": "http://snomed.info/sct",
    "version": "2022-03",
    "code": "182922004",
    "display": "Dietary regime (regime/therapy)",
    "userSelected": true
  }
]
```
OK! This patient has ServiceRequest that looks promising. 
Grab the first ValueSet from the table above. 
```
jq '.expansion.contains[] | select(.code == "182922004")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1525.json
```
Returns
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "182922004",
  "display": "Dietary regime (regime/therapy)"
}
```
But here there's a catch. This coding element is part of a 'do not perform' resource, part of the Exception logic. Just be aware, we have shown that our logic is solid, but this case is actually excluded from scoring. 

##### Next Valueset

Find a positive test case for ServiceRequest|"Referrals Where Weight Assessment May Occur"|2.16.840.1.113883.3.600.1.1527.

7ac9722f-8763-4380-a741-53ee4bb98819/CMS69FHIR-v0.3.000-DENEXCEPPass-NotRequestedReferralForHighBMI

This one also happens to be a *not performed case*

```
jq '
  .entry[]
  | select(.resource.resourceType == "ServiceRequest")
  | .resource.code[]
' CMS69-bmi_0.3.000/test-cases/7ac9722f-8763-4380-a741-53ee4bb98819/CMS69FHIR-v0.3.000-DENEXCEPPass-NotRequestedReferralForHighBMI.json
```
=>
```
[
  {
    "system": "http://snomed.info/sct",
    "version": "2022-03",
    "code": "103699006",
    "display": "Patient referral to dietitian (procedure)",
    "userSelected": true
  }
]
```
Checking the valueset

```
jq '.expansion.contains[] | select(.code == "103699006")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.600.1.1527.json
```
confirms
```
{
  "system": "http://snomed.info/sct",
  "version": "http://snomed.info/sct/731000124108/version/20240901",
  "code": "103699006",
  "display": "Referral to dietitian (procedure)"
}
```
And for the MedicationRequest
6553adbf-2a30-4861-97e6-cca7d2274f01/CMS69FHIR-v0.3.000-DENEXCEPPass-NoFollowUpPlanMedicalReasonMedicationForAboveNormalBMI
```
jq '
  .entry[]
  | select(.resource.resourceType == "MedicationRequest")
  | .resource.medicationCodeableConcept[]
' CMS69-bmi_0.3.000/test-cases/6553adbf-2a30-4861-97e6-cca7d2274f01/CMS69FHIR-v0.3.000-DENEXCEPPass-NoFollowUpPlanMedicalReasonMedicationForAboveNormalBMI.json
```
```
[
  {
    "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
    "code": "1112982",
    "display": "phentermine hydrochloride 15 MG Disintegrating Oral Tablet",
    "userSelected": true
  }
]
```
```
jq '.expansion.contains[] | select(.code == "1112982")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1561.json
```
```
{
  "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
  "version": "03032025",
  "code": "1112982",
  "display": "phentermine hydrochloride 15 MG Disintegrating Oral Tablet"
}
```
To do this round trip I first start by 
- opening the values
- start from the code at the top
- search all test cases for that code
- go to next code if not found
- repeat until a case is found
- run that case resource query
- harvest the code and run a valueset query. 

So if I pick a case based on a code from the valueset, of course I should end up a hit when I go back and look for the code in the valueset. It's a way to validate the jq query. 

##### Aside

To query a valueset for its first expansion element:
```
jq '.expansion.contains[0]' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113883.3.526.3.1561.json
```

##### Next line of CQL
```
define "High BMI Interventions Ordered":
  ( ( [ServiceRequest: "Follow Up for Above Normal BMI"]
      union [ServiceRequest: "Referrals Where Weight Assessment May Occur"]
      union [MedicationRequest: "Medications for Above Normal BMI"] ) HighInterventionsOrdered
      where HighInterventionsOrdered.reasonCode in "Overweight or Obese"
...
```
We've gotten through MedicationRequest. Now to examine `where HighInterventionsOrdered.reasonCode in "Overweight or Obese"`. 

|resource|element|valueset|
|---|---|---|
|MedicationRequest|reason|2.16.840.1.113762.1.4.1047.502|

Looking at our standard test case *0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json*

```
jq '
  select(.resource.resourceType == "MedicationRequest")
  .resource.reasonCode[]
' CMS69-bmi_0.3.000/test-cases/0278fdf0-f067-46e8-aeb1-fb96dff3c947/CMS69FHIR-v0.3.000-DENEXCEPPass-HTN130DeclinedNonPharm.json
```
Sorry kid, no MedicationRequest resource. 

Test case with MedicationRequest: *27849d59-3cef-40bf-8338-a6ec7c0bcf81/CMS69FHIR-v0.3.000-NUMERPass-LowBMIAndInterventionOrderedMedication*

```
jq '
  .entry[]
  | select(.resource.resourceType == "MedicationRequest")
  | .resource.reasonCode[]
' CMS69-bmi_0.3.000/test-cases/27849d59-3cef-40bf-8338-a6ec7c0bcf81/CMS69FHIR-v0.3.000-NUMERPass-LowBMIAndInterventionOrderedMedication.json
```
=>
```
{
  "coding": [
    {
      "system": "http://hl7.org/fhir/sid/icd-10-cm",
      "code": "R63.6",
      "display": "Underweight",
      "userSelected": true
    }
  ]
}
```
This is probably not the test case we want right now. Save it for the **Not enough** section. 

New test case. 
- 050201c2-c2c4-46e6-8288-a34f99caebdc/CMS69FHIR-v0.3.000-NUMERPass-HighBMIAndIntervenionOrderedMedication
```
jq '
  .entry[]
  | select(.resource.resourceType == "MedicationRequest")
  | .resource.reasonCode[]
' CMS69-bmi_0.3.000/test-cases/050201c2-c2c4-46e6-8288-a34f99caebdc/CMS69FHIR-v0.3.000-NUMERPass-HighBMIAndIntervenionOrderedMedication.json
```
```
jq '.expansion.contains[] | select(.code == "E66.01")' CMS69-bmi_0.3.000/vocabulary/valueset/external/2.16.840.1.113762.1.4.1047.502.json
```
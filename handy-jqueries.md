### Patient Age
jq '.entry[0].resource.birthDate' {test-patient-file} e.g.

jq '.entry[0].resource.birthDate' CMS69-bmi_0.3.000/test-cases/296d38e4-d69b-481e-a8cf-f7eee8b9e5d7/CMS69FHIR-v0.3.000-IPPPass-Age18HasEnc.json

### Encounter date
jq -r '.entry[] 
  | select(.resource.resourceType == "Encounter") 
  | .resource.period.start' {filePath}

### All resources in a Bundle

jq -r '.entry[].resource.resourceType'
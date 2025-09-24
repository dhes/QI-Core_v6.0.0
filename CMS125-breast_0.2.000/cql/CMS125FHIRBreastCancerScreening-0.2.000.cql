library CMS125FHIRBreastCancerScreening version '0.2.000'

using QICore version '6.0.0'

include FHIRHelpers version '4.4.000' called FHIRHelpers
include SupplementalDataElements version '5.1.000' called SDE
include QICoreCommon version '4.0.000' called QICoreCommon
include AdultOutpatientEncounters version '4.15.000' called AdultOutpatientEncounters
include Hospice version '6.15.000' called Hospice
include Status version '1.13.000' called Status
include PalliativeCare version '1.15.000' called PalliativeCare
include AdvancedIllnessandFrailty version '1.22.000' called AIFrailLTCF

codesystem "AdministrativeGender": 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

valueset "Bilateral Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1005'
valueset "History of bilateral mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1068'
valueset "Mammography": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.108.12.1018'
valueset "Status Post Left Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1069'
valueset "Status Post Right Mastectomy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1070'
valueset "Unilateral Mastectomy Left": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1133'
valueset "Unilateral Mastectomy Right": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1134'
valueset "Unilateral Mastectomy, Unspecified Laterality": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1071'

code "Female": 'F' from "AdministrativeGender" display 'Female'
code "Left (qualifier value)": '7771000' from "SNOMEDCT" display 'Left (qualifier value)'
code "Right (qualifier value)": '24028007' from "SNOMEDCT" display 'Right (qualifier value)'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Initial Population":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[42, 74]
    and Patient.gender = 'female'
    and exists AdultOutpatientEncounters."Qualifying Encounters"

define "Denominator":
  "Initial Population"

define "Denominator Exclusions":
  Hospice."Has Hospice Services"
    or ( ( exists ( "Right Mastectomy Diagnosis" )
          or exists ( "Right Mastectomy Procedure" )
      )
        and ( exists ( "Left Mastectomy Diagnosis" )
            or exists ( "Left Mastectomy Procedure" )
        )
    )
    or exists "Bilateral Mastectomy Diagnosis"
    or exists "Bilateral Mastectomy Procedure"
    or AIFrailLTCF."Is Age 66 or Older with Advanced Illness and Frailty"
    or AIFrailLTCF."Is Age 66 or Older Living Long Term in a Nursing Home"
    or PalliativeCare."Has Palliative Care in the Measurement Period"

define "Right Mastectomy Diagnosis":
  ( ( [ConditionEncounterDiagnosis: "Status Post Right Mastectomy"]
    union [ConditionProblemsHealthConcerns: "Status Post Right Mastectomy"] ) RightMastectomyProcedure
    union ( ( [ConditionEncounterDiagnosis: "Unilateral Mastectomy, Unspecified Laterality"]
        union [ConditionProblemsHealthConcerns: "Unilateral Mastectomy, Unspecified Laterality"] ) UnilateralMastectomyDiagnosis
        where exists ( UnilateralMastectomyDiagnosis.bodySite S
            where S ~ "Right (qualifier value)"
        )
    ) ) RightMastectomy
    where RightMastectomy.prevalenceInterval ( ) starts on or before end of "Measurement Period"

define "Right Mastectomy Procedure":
  ( ( [Procedure: "Unilateral Mastectomy Right"] ).isProcedurePerformed ( ) ) UnilateralMastectomyRightPerformed
    where UnilateralMastectomyRightPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Left Mastectomy Diagnosis":
  ( ( [ConditionEncounterDiagnosis: "Status Post Left Mastectomy"]
      union [ConditionProblemsHealthConcerns: "Status Post Left Mastectomy"]
      union ( [ConditionEncounterDiagnosis: "Unilateral Mastectomy, Unspecified Laterality"]
        union [ConditionProblemsHealthConcerns: "Unilateral Mastectomy, Unspecified Laterality"] ) UnilateralMastectomyDiagnosis
        where exists ( UnilateralMastectomyDiagnosis.bodySite S
            where S ~ "Left (qualifier value)"
        )
  ) ) LeftMastectomy
    where LeftMastectomy.prevalenceInterval ( ) starts on or before end of "Measurement Period"

define "Left Mastectomy Procedure":
  ( ( [Procedure: "Unilateral Mastectomy Left"] ).isProcedurePerformed ( ) ) UnilateralMastectomyLeftPerformed
    where UnilateralMastectomyLeftPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Bilateral Mastectomy Diagnosis":
  ( ( ( [ConditionEncounterDiagnosis: "History of bilateral mastectomy"] )
      union ( [ConditionProblemsHealthConcerns: "History of bilateral mastectomy"] ) ) BilateralMastectomyHistory
      where BilateralMastectomyHistory.prevalenceInterval ( ) starts on or before end of "Measurement Period"
  )

define "Bilateral Mastectomy Procedure":
  ( ( [Procedure: "Bilateral Mastectomy"] ).isProcedurePerformed ( ) ) BilateralMastectomyPerformed
    where BilateralMastectomyPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"

define "Numerator":
  exists ( ( ( [ObservationClinicalResult: "Mammography"] ).isDiagnosticStudyPerformed ( ) ) Mammogram
      where Mammogram.effective.toInterval ( ) ends during day of Interval["October 1 Two Years Prior to the Measurement Period", end of "Measurement Period"]
  )

define "October 1 Two Years Prior to the Measurement Period":
  DateTime((year from start of "Measurement Period" - 2), 10, 1, 0, 0, 0, 0, 0)

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "Stratification 1":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[42, 51]

define "Stratification 2":
  AgeInYearsAt(date from 
    end of "Measurement Period"
  ) in Interval[52, 74]


86MilesPressure)


{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "parameters",
      "resource": {
        "resourceType": "Parameters",
        "parameter": [
          {
            "name": "Measurement Period",
            "valuePeriod": {
              "start": "2026-01-01",
              "end": "2026-01-01"
            }
          }
        ]
      }
    }
  ]
}

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "subject",
      "valueString": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
    },
    {
      "name": "Measurement Period",
      "valuePeriod": {
        "begin": "2026-01-01T00:00:00",
        "end": "2026-12-31T23:59:59"
      }
    }
  ]
}


curl 'https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate' \
  -X OPTIONS \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0' \
  -H 'Accept: */*' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate, br, zstd' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type' \
  -H 'Referer: http://localhost:5173/' \
  -H 'Origin: http://localhost:5173' \
  -H 'Connection: keep-alive' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: cross-site' \
  -H 'Priority: u=4'

https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate
{
  "log": {
    "version": "1.2",
    "creator": {
      "name": "Firefox",
      "version": "142.0"
    },
    "browser": {
      "name": "Firefox",
      "version": "142.0"
    },
    "pages": [
      {
        "id": "page_1",
        "pageTimings": {
          "onContentLoad": -39356,
          "onLoad": -39179
        },
        "startedDateTime": "2025-09-06T18:04:29.149-10:00",
        "title": "http://localhost:5173/"
      }
    ],
    "entries": [
      {
        "startedDateTime": "2025-09-06T18:04:29.149-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Encounter?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "mRoISekc04E8RDmq"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 1518,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"3f775b5d-01c4-4d80-bdb9-16e83842d5c7\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.067+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 1,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Encounter?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/54811508-b000-4435-b719-ba4be48ba643\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"54811508-b000-4435-b719-ba4be48ba643\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99401\",\n          \"display\": \"Preventive medicine counseling and/or risk factor reduction intervention(s) provided to an individual (separate procedure); approximately 15 minutes\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 1357
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 129,
          "receive": 0
        },
        "time": 129,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.150-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/MedicationRequest?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 533
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "KWSWNLWCVxhJ7Lrf"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 347,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"40f74aa9-3d1f-459c-b7ad-ae1062fdd799\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.075+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/MedicationRequest?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 911
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 105,
          "receive": 0
        },
        "time": 105,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.152-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/ServiceRequest?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 530
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "qClVJ9yDZ3eJIgaQ"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 344,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"d28709a7-f5d1-4bc0-8db2-ea4b152157af\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.072+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/ServiceRequest?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 910
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 98,
          "receive": 0
        },
        "time": 98,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.154-10:00",
        "request": {
          "bodySize": 0,
          "method": "POST",
          "url": "https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate",
          "httpVersion": "",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json"
            },
            {
              "name": "Content-Length",
              "value": "304"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            }
          ],
          "cookies": [],
          "queryString": [],
          "headersSize": 0
        },
        "response": {
          "status": 0,
          "statusText": "",
          "httpVersion": "",
          "headers": [],
          "cookies": [],
          "content": {
            "size": 0,
            "encoding": "base64",
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 0,
          "bodySize": -1
        },
        "cache": {},
        "timings": {},
        "time": 0,
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.155-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Patient?_id=d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "_id",
              "value": "d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 511
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "vJtmgXTAaElcOI6d"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 1883,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"1afde9f5-75f8-4d1f-8947-627642039741\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.073+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 1,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Patient?_id=d7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c\",\n    \"resource\": {\n      \"resourceType\": \"Patient\",\n      \"id\": \"d7c6ac3f-09f8-46d5-8231-8b32554fef9c\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-patient\" ]\n      },\n      \"extension\": [ {\n        \"url\": \"http://hl7.org/fhir/us/core/StructureDefinition/us-core-race\",\n        \"extension\": [ {\n          \"url\": \"ombCategory\",\n          \"valueCoding\": {\n            \"system\": \"urn:oid:2.16.840.1.113883.6.238\",\n            \"code\": \"2028-9\",\n            \"display\": \"Asian\"\n          }\n        }, {\n          \"url\": \"text\",\n          \"valueString\": \"Asian\"\n        } ]\n      }, {\n        \"url\": \"http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity\",\n        \"extension\": [ {\n          \"url\": \"ombCategory\",\n          \"valueCoding\": {\n            \"system\": \"urn:oid:2.16.840.1.113883.6.238\",\n            \"code\": \"2135-2\",\n            \"display\": \"Hispanic or Latino\"\n          }\n        }, {\n          \"url\": \"text\",\n          \"valueString\": \"Hispanic or Latino\"\n        } ]\n      } ],\n      \"identifier\": [ {\n        \"system\": \"http://hospital.smarthealthit.org\",\n        \"value\": \"999999995\"\n      } ],\n      \"name\": [ {\n        \"family\": \"Bertha\",\n        \"given\": [ \"Betty\" ]\n      } ],\n      \"gender\": \"female\",\n      \"birthDate\": \"2013-12-31\"\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 1312
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 127,
          "receive": 0
        },
        "time": 127,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.156-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Measure/CMS138FHIRPreventiveTobaccoCessation/$evaluate-measure?subject=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&periodStart=2026-01-01T00:00:00&periodEnd=2026-12-31T23:59:59",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "subject",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "periodStart",
              "value": "2026-01-01T00:00:00"
            },
            {
              "name": "periodEnd",
              "value": "2026-12-31T23:59:59"
            }
          ],
          "headersSize": 590
        },
        "response": {
          "status": 404,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "yxmYgscZKqhqe404"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 234,
            "text": "{\n  \"resourceType\": \"OperationOutcome\",\n  \"issue\": [ {\n    \"severity\": \"error\",\n    \"code\": \"processing\",\n    \"diagnostics\": \"Unable to find Library with url: https://madie.cms.gov/Library/CMS138FHIRPreventiveTobaccoCessation\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 520,
          "bodySize": 754
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 136,
          "receive": 0
        },
        "time": 136,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.156-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Encounter?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 475
        },
        "response": {
          "status": 0,
          "statusText": "",
          "httpVersion": "",
          "headers": [],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 1518,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"3f775b5d-01c4-4d80-bdb9-16e83842d5c7\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.067+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 1,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Encounter?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/54811508-b000-4435-b719-ba4be48ba643\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"54811508-b000-4435-b719-ba4be48ba643\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99401\",\n          \"display\": \"Preventive medicine counseling and/or risk factor reduction intervention(s) provided to an individual (separate procedure); approximately 15 minutes\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 0,
          "bodySize": 715
        },
        "cache": {},
        "timings": {
          "blocked": 74,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 0,
          "receive": 0
        },
        "time": 74,
        "_securityState": "secure",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.157-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/AllergyIntolerance?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 534
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "4KxqubFtDq0xT0nS"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 348,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"d015ac5d-37dc-40a6-a148-c9ba77f1d2e0\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.080+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/AllergyIntolerance?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 912
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 109,
          "receive": 0
        },
        "time": 109,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.158-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Condition?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "IfC2Si5OFQXG21aI"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 339,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"8c0a9683-4b5b-4dae-9140-6f235874724c\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.081+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Condition?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 904
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 111,
          "receive": 0
        },
        "time": 111,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.158-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/MedicationStatement?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 535
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "vOksoDz9Lo2omox6"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 349,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"673168d3-19cc-4d68-aa73-82a29d924deb\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.078+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/MedicationStatement?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 912
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 105,
          "receive": 0
        },
        "time": 105,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.158-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/FamilyMemberHistory?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 535
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "AejDlY372IVTXyzU"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 349,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"025bf993-586c-4ef6-bb9a-f512b4e8d4f0\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.141+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/FamilyMemberHistory?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 915
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 71,
          "ssl": 71,
          "send": 0,
          "wait": 83,
          "receive": 0
        },
        "time": 225,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.159-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Immunization?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 528
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "JhcNtdhdLco0qRf6"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 342,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"e7e3fa8e-3d02-45e6-81b6-b8c3fb877abc\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.284+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Immunization?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 908
        },
        "cache": {},
        "timings": {
          "blocked": 92,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 79,
          "receive": 0
        },
        "time": 171,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.159-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Procedure?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "eQN4dXC7UfOyiv45"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 339,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"657b9975-88b3-45d1-9df4-a2d8bea263a3\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.285+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Procedure?patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 905
        },
        "cache": {},
        "timings": {
          "blocked": 103,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 89,
          "receive": 0
        },
        "time": 192,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.160-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&category=http%3A%2F%2Fterminology.hl7.org%2FCodeSystem%2Fobservation-category%7Claboratory",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "category",
              "value": "http://terminology.hl7.org/CodeSystem/observation-category|laboratory"
            }
          ],
          "headersSize": 618
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "4BS0PiE63CiXmIpk"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 432,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"fdb098ed-0c23-40f5-b33b-8dd201e15f15\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.280+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?category=http%3A%2F%2Fterminology.hl7.org%2FCodeSystem%2Fobservation-category%7Claboratory&patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 960
        },
        "cache": {},
        "timings": {
          "blocked": 110,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 98,
          "receive": 0
        },
        "time": 208,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.160-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&code=http%3A%2F%2Floinc.org%7C72166-2",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "code",
              "value": "http://loinc.org|72166-2"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "VCSYQmJvYgLCUJyk"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"e1dac8e5-e6d0-4c6a-b022-c2b441177bc2\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.281+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C72166-2&patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 932
        },
        "cache": {},
        "timings": {
          "blocked": 120,
          "dns": 0,
          "connect": 72,
          "ssl": 0,
          "send": 0,
          "wait": 94,
          "receive": 0
        },
        "time": 286,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.160-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&code=http%3A%2F%2Floinc.org%7C39240-7",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "code",
              "value": "http://loinc.org|39240-7"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "YaIZajjWgFz4Rmc3"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"a7f1e558-42ac-44db-ab32-11f5f50a9b35\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.282+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C39240-7&patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 932
        },
        "cache": {},
        "timings": {
          "blocked": 133,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 88,
          "receive": 0
        },
        "time": 221,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.161-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&code=http%3A%2F%2Floinc.org%7C68535-4",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "code",
              "value": "http://loinc.org|68535-4"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "xOZBLj1Hr4vlE8ua"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"f032de04-004e-4e3c-81a9-9d6733a40874\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.279+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C68535-4&patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 932
        },
        "cache": {},
        "timings": {
          "blocked": 119,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 94,
          "receive": 0
        },
        "time": 213,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.161-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c&code=http%3A%2F%2Floinc.org%7C68536-2",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/d7c6ac3f-09f8-46d5-8231-8b32554fef9c"
            },
            {
              "name": "code",
              "value": "http://loinc.org|68536-2"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "l0kbrd56CnMZo3zK"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:04:08 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"62e8548c-baee-4226-a418-ca8c5fbf0404\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:04:08.283+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C68536-2&patient=Patient%2Fd7c6ac3f-09f8-46d5-8231-8b32554fef9c\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 932
        },
        "cache": {},
        "timings": {
          "blocked": 108,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 97,
          "receive": 0
        },
        "time": 205,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.161-10:00",
        "request": {
          "bodySize": 255,
          "method": "POST",
          "url": "http://localhost:5173/cds-services/TobaccoRecommendation",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "localhost:5173"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Content-Type",
              "value": "application/json"
            },
            {
              "name": "Content-Length",
              "value": "255"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Cookie",
              "value": "intercom-id-fqdpw3fp=ea92200c-164d-428c-a67f-a2ef1a186b5b; intercom-device-id-fqdpw3fp=bb9651de-6ea8-4f8e-9f65-4786e457d97d"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "same-origin"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [
            {
              "name": "intercom-id-fqdpw3fp",
              "value": "ea92200c-164d-428c-a67f-a2ef1a186b5b"
            },
            {
              "name": "intercom-device-id-fqdpw3fp",
              "value": "bb9651de-6ea8-4f8e-9f65-4786e457d97d"
            }
          ],
          "queryString": [],
          "headersSize": 624,
          "postData": {
            "mimeType": "application/json",
            "params": [],
            "text": "{\"hookInstance\":\"patient-view-d7c6ac3f-09f8-46d5-8231-8b32554fef9c-1757217869150\",\"fhirServer\":\"http://localhost:8080/fhir\",\"hook\":\"patient-view\",\"context\":{\"patientId\":\"d7c6ac3f-09f8-46d5-8231-8b32554fef9c\",\"userId\":\"Practitioner/example\"},\"prefetch\":{}}"
          }
        },
        "response": {
          "status": 500,
          "statusText": "Internal Server Error",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Content-Type",
              "value": "text/plain"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Keep-Alive",
              "value": "timeout=5"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "text/plain",
            "size": 0,
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 242,
          "bodySize": 1121
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 2,
          "receive": 0
        },
        "time": 2,
        "_securityState": "insecure",
        "serverIPAddress": "::1",
        "connection": "5173",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:29.162-10:00",
        "request": {
          "bodySize": 0,
          "method": "OPTIONS",
          "url": "https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Access-Control-Request-Method",
              "value": "POST"
            },
            {
              "name": "Access-Control-Request-Headers",
              "value": "content-type"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=4"
            }
          ],
          "cookies": [],
          "queryString": [],
          "headersSize": 525
        },
        "response": {
          "status": 204,
          "statusText": "No Content",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:29 GMT"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "https://cql-runner.dataphoria.org"
            },
            {
              "name": "Access-Control-Allow-Methods",
              "value": "GET, POST, PUT, DELETE, OPTIONS"
            },
            {
              "name": "Access-Control-Allow-Headers",
              "value": "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
            },
            {
              "name": "Access-Control-Max-Age",
              "value": "1728000"
            },
            {
              "name": "Content-Type",
              "value": "text/plain; charset=utf-8"
            },
            {
              "name": "Content-Length",
              "value": "0"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "text/plain; charset=utf-8",
            "size": 0,
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 467,
          "bodySize": 467
        },
        "cache": {},
        "timings": {
          "blocked": 207,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 70,
          "receive": 0
        },
        "time": 277,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.350-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Encounter?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "By6xlvDcvDMITpSs"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 2643,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"42c2fc57-f8ec-4658-8c5e-db7eef1c52a0\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.322+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 2,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Encounter?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/86e20c25-653c-437e-b51c-cc315cd1701f\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"86e20c25-653c-437e-b51c-cc315cd1701f\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99429\",\n          \"display\": \"Unlisted preventive medicine service\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  }, {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/3de9d589-826b-424d-9067-6b49e64702b0\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"3de9d589-826b-424d-9067-6b49e64702b0\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99024\",\n          \"display\": \"Postoperative follow-up visit, normally included in the surgical package, to indicate that an evaluation and management service was performed during a postoperative period for a reason(s) related to the original procedure\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 1477
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 140,
          "receive": 0
        },
        "time": 140,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/MedicationRequest?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 533
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "3AlS9H4YwpqbKhNN"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 347,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"558a5cab-3a42-40d8-968f-4e4590b3c05c\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.320+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/MedicationRequest?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 911
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 118,
          "receive": 0
        },
        "time": 118,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/ServiceRequest?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 530
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "fQQAX2tVneNk7tVE"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 344,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"f90caeae-4077-4d2a-b449-648ad0c313cd\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.322+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/ServiceRequest?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 909
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 118,
          "receive": 0
        },
        "time": 118,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "POST",
          "url": "https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate",
          "httpVersion": "",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json"
            },
            {
              "name": "Content-Length",
              "value": "304"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            }
          ],
          "cookies": [],
          "queryString": [],
          "headersSize": 0
        },
        "response": {
          "status": 0,
          "statusText": "",
          "httpVersion": "",
          "headers": [],
          "cookies": [],
          "content": {
            "size": 0,
            "encoding": "base64",
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 0,
          "bodySize": -1
        },
        "cache": {},
        "timings": {},
        "time": 0,
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Patient?_id=ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "_id",
              "value": "ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 511
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "zPk51tZViBbfppws"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 1883,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"71100834-c802-4d31-86bb-a7d0be20fc17\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.323+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 1,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Patient?_id=ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\",\n    \"resource\": {\n      \"resourceType\": \"Patient\",\n      \"id\": \"ed2fe491-3eb7-424a-bf95-5d44b6102cec\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-patient\" ]\n      },\n      \"extension\": [ {\n        \"url\": \"http://hl7.org/fhir/us/core/StructureDefinition/us-core-race\",\n        \"extension\": [ {\n          \"url\": \"ombCategory\",\n          \"valueCoding\": {\n            \"system\": \"urn:oid:2.16.840.1.113883.6.238\",\n            \"code\": \"2028-9\",\n            \"display\": \"Asian\"\n          }\n        }, {\n          \"url\": \"text\",\n          \"valueString\": \"Asian\"\n        } ]\n      }, {\n        \"url\": \"http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity\",\n        \"extension\": [ {\n          \"url\": \"ombCategory\",\n          \"valueCoding\": {\n            \"system\": \"urn:oid:2.16.840.1.113883.6.238\",\n            \"code\": \"2135-2\",\n            \"display\": \"Hispanic or Latino\"\n          }\n        }, {\n          \"url\": \"text\",\n          \"valueString\": \"Hispanic or Latino\"\n        } ]\n      } ],\n      \"identifier\": [ {\n        \"system\": \"http://hospital.smarthealthit.org\",\n        \"value\": \"999999995\"\n      } ],\n      \"name\": [ {\n        \"family\": \"Bertha\",\n        \"given\": [ \"Betty\" ]\n      } ],\n      \"gender\": \"female\",\n      \"birthDate\": \"2013-12-31\"\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 1313
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 140,
          "receive": 0
        },
        "time": 140,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Measure/CMS138FHIRPreventiveTobaccoCessation/$evaluate-measure?subject=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&periodStart=2026-01-01T00:00:00&periodEnd=2026-12-31T23:59:59",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "subject",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "periodStart",
              "value": "2026-01-01T00:00:00"
            },
            {
              "name": "periodEnd",
              "value": "2026-12-31T23:59:59"
            }
          ],
          "headersSize": 590
        },
        "response": {
          "status": 404,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "f0oFvkdc7G3gcgz7"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 234,
            "text": "{\n  \"resourceType\": \"OperationOutcome\",\n  \"issue\": [ {\n    \"severity\": \"error\",\n    \"code\": \"processing\",\n    \"diagnostics\": \"Unable to find Library with url: https://madie.cms.gov/Library/CMS138FHIRPreventiveTobaccoCessation\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 520,
          "bodySize": 754
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 149,
          "receive": 0
        },
        "time": 149,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.351-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Encounter?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 475
        },
        "response": {
          "status": 0,
          "statusText": "",
          "httpVersion": "",
          "headers": [],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 2643,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"42c2fc57-f8ec-4658-8c5e-db7eef1c52a0\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.322+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 2,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Encounter?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/86e20c25-653c-437e-b51c-cc315cd1701f\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"86e20c25-653c-437e-b51c-cc315cd1701f\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99429\",\n          \"display\": \"Unlisted preventive medicine service\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  }, {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Encounter/3de9d589-826b-424d-9067-6b49e64702b0\",\n    \"resource\": {\n      \"resourceType\": \"Encounter\",\n      \"id\": \"3de9d589-826b-424d-9067-6b49e64702b0\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter\" ]\n      },\n      \"status\": \"finished\",\n      \"class\": {\n        \"system\": \"http://terminology.hl7.org/CodeSystem/v3-ActCode\",\n        \"code\": \"AMB\",\n        \"display\": \"ambulatory\"\n      },\n      \"type\": [ {\n        \"coding\": [ {\n          \"system\": \"http://www.ama-assn.org/go/cpt\",\n          \"code\": \"99024\",\n          \"display\": \"Postoperative follow-up visit, normally included in the surgical package, to indicate that an evaluation and management service was performed during a postoperative period for a reason(s) related to the original procedure\"\n        } ]\n      } ],\n      \"subject\": {\n        \"reference\": \"Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n      },\n      \"period\": {\n        \"start\": \"2026-01-01T01:00:00.000Z\",\n        \"end\": \"2026-01-01T01:15:00.000Z\"\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 0,
          "bodySize": 835
        },
        "cache": {},
        "timings": {
          "blocked": 85,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 0,
          "receive": 0
        },
        "time": 85,
        "_securityState": "secure",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.352-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/AllergyIntolerance?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 534
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "B2YzbIYsHtWUwkta"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 348,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"9c2daff9-0220-4b47-843f-66d5d046bc79\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.391+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/AllergyIntolerance?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 912
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 107,
          "receive": 0
        },
        "time": 107,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.352-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Condition?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "vEbiUL12HEOGmw27"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 339,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"518ff39b-f33f-4eb3-b51f-eb67f5e5653a\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.466+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Condition?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 904
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 111,
          "receive": 0
        },
        "time": 111,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.352-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/MedicationStatement?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 535
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "BXO0AzOqpb7Y8AuF"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 349,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"4cb6da82-f06b-4bdb-867e-c8d6348ccd4f\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.473+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/MedicationStatement?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 910
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 131,
          "receive": 0
        },
        "time": 131,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.352-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/FamilyMemberHistory?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 535
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "G4KB0yfP7muW2odT"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 349,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"af24c898-489b-4f04-9d42-9f51112f3f7f\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.432+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/FamilyMemberHistory?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 915
        },
        "cache": {},
        "timings": {
          "blocked": -1,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 126,
          "receive": 0
        },
        "time": 126,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.353-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Immunization?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 528
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "EVtCoVP1RT6GnlGk"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 342,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"37246757-a953-4662-a8e0-62b562e6f394\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.445+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Immunization?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 908
        },
        "cache": {},
        "timings": {
          "blocked": 117,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 81,
          "receive": 0
        },
        "time": 198,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.354-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Procedure?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            }
          ],
          "headersSize": 525
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "Roh1omhRpjPoQSaA"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 339,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"9d0ac576-0a43-4af9-966c-273679fbc636\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.471+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Procedure?patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 904
        },
        "cache": {},
        "timings": {
          "blocked": 130,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 90,
          "receive": 0
        },
        "time": 220,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.355-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&category=http%3A%2F%2Fterminology.hl7.org%2FCodeSystem%2Fobservation-category%7Claboratory",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "category",
              "value": "http://terminology.hl7.org/CodeSystem/observation-category|laboratory"
            }
          ],
          "headersSize": 618
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "P6TO1W7BfBnOsXp4"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 432,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"f6878b63-4efe-44d8-b3ea-016fac75e973\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.598+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?category=http%3A%2F%2Fterminology.hl7.org%2FCodeSystem%2Fobservation-category%7Claboratory&patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 962
        },
        "cache": {},
        "timings": {
          "blocked": 138,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 91,
          "receive": 0
        },
        "time": 229,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.355-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&code=http%3A%2F%2Floinc.org%7C72166-2",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "code",
              "value": "http://loinc.org|72166-2"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "885Zbs5pwbvzYGTB"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"4e94abc3-1abc-4827-921d-fc77726b20fa\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.602+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C72166-2&patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 931
        },
        "cache": {},
        "timings": {
          "blocked": 138,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 88,
          "receive": 0
        },
        "time": 226,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.356-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&code=http%3A%2F%2Floinc.org%7C39240-7",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "code",
              "value": "http://loinc.org|39240-7"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "2qM3YJEgk5A9upvk"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 1642,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"f9f95865-7d84-4f7d-9c21-f5ade0aa1428\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.473+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 1,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C39240-7&patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ],\n  \"entry\": [ {\n    \"fullUrl\": \"http://enhanced.hopena.info/fhir/Observation/e4d7ec90-d517-41d7-abc3-e2861b95023b\",\n    \"resource\": {\n      \"resourceType\": \"Observation\",\n      \"id\": \"e4d7ec90-d517-41d7-abc3-e2861b95023b\",\n      \"meta\": {\n        \"versionId\": \"1\",\n        \"lastUpdated\": \"2025-09-02T22:07:45.747+00:00\",\n        \"profile\": [ \"http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus\" ]\n      },\n      \"status\": \"final\",\n      \"category\": [ {\n        \"coding\": [ {\n          \"system\": \"http://terminology.hl7.org/CodeSystem/observation-category\",\n          \"code\": \"survey\",\n          \"display\": \"survey\"\n        } ],\n        \"text\": \"survey\"\n      } ],\n      \"code\": {\n        \"coding\": [ {\n          \"system\": \"http://loinc.org\",\n          \"code\": \"39240-7\",\n          \"display\": \"Tobacco use status CPHS\"\n        } ]\n      },\n      \"subject\": {\n        \"reference\": \"Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n      },\n      \"effectiveDateTime\": \"2026-01-01T01:00:00.000Z\",\n      \"valueCodeableConcept\": {\n        \"coding\": [ {\n          \"system\": \"http://snomed.info/sct\",\n          \"code\": \"110483000\",\n          \"display\": \"Tobacco user (finding)\"\n        } ]\n      }\n    },\n    \"search\": {\n      \"mode\": \"match\"\n    }\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 1327
        },
        "cache": {},
        "timings": {
          "blocked": 124,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 99,
          "receive": 0
        },
        "time": 223,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.357-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&code=http%3A%2F%2Floinc.org%7C68535-4",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "code",
              "value": "http://loinc.org|68535-4"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "VW0NkVirJwsKjNxw"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"c480ab78-8d3f-4cec-b4d2-01a6dfea0e19\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.449+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C68535-4&patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 933
        },
        "cache": {},
        "timings": {
          "blocked": 116,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 94,
          "receive": 0
        },
        "time": 210,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.357-10:00",
        "request": {
          "bodySize": 0,
          "method": "GET",
          "url": "https://enhanced.hopena.info/fhir/Observation?patient=Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec&code=http%3A%2F%2Floinc.org%7C68536-2",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "If-Modified-Since",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [],
          "queryString": [
            {
              "name": "patient",
              "value": "Patient/ed2fe491-3eb7-424a-bf95-5d44b6102cec"
            },
            {
              "name": "code",
              "value": "http://loinc.org|68536-2"
            }
          ],
          "headersSize": 565
        },
        "response": {
          "status": 200,
          "statusText": "",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Content-Type",
              "value": "application/fhir+json;charset=UTF-8"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Method"
            },
            {
              "name": "Vary",
              "value": "Access-Control-Request-Headers"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Access-Control-Expose-Headers",
              "value": "Location, Content-Location"
            },
            {
              "name": "Access-Control-Allow-Credentials",
              "value": "true"
            },
            {
              "name": "X-Cache",
              "value": "HIT from http://enhanced.hopena.info/fhir"
            },
            {
              "name": "X-Powered-By",
              "value": "HAPI FHIR 8.2.0 REST Server (FHIR Server; FHIR 4.0.1/R4)"
            },
            {
              "name": "X-Request-ID",
              "value": "Xtr8iIkhgOP4zvlN"
            },
            {
              "name": "Last-Modified",
              "value": "Sun, 07 Sep 2025 04:03:53 GMT"
            },
            {
              "name": "Content-Encoding",
              "value": "gzip"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "application/fhir+json; charset=UTF-8",
            "size": 379,
            "text": "{\n  \"resourceType\": \"Bundle\",\n  \"id\": \"21c6deda-f8d4-4beb-acc8-91ef823f7a71\",\n  \"meta\": {\n    \"lastUpdated\": \"2025-09-07T04:03:53.442+00:00\"\n  },\n  \"type\": \"searchset\",\n  \"total\": 0,\n  \"link\": [ {\n    \"relation\": \"self\",\n    \"url\": \"http://enhanced.hopena.info/fhir/Observation?code=http%3A%2F%2Floinc.org%7C68536-2&patient=Patient%2Fed2fe491-3eb7-424a-bf95-5d44b6102cec\"\n  } ]\n}"
          },
          "redirectURL": "",
          "headersSize": 642,
          "bodySize": 932
        },
        "cache": {},
        "timings": {
          "blocked": 105,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 79,
          "receive": 0
        },
        "time": 184,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.357-10:00",
        "request": {
          "bodySize": 255,
          "method": "POST",
          "url": "http://localhost:5173/cds-services/TobaccoRecommendation",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "localhost:5173"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Content-Type",
              "value": "application/json"
            },
            {
              "name": "Content-Length",
              "value": "255"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Cookie",
              "value": "intercom-id-fqdpw3fp=ea92200c-164d-428c-a67f-a2ef1a186b5b; intercom-device-id-fqdpw3fp=bb9651de-6ea8-4f8e-9f65-4786e457d97d"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "same-origin"
            },
            {
              "name": "Priority",
              "value": "u=0"
            }
          ],
          "cookies": [
            {
              "name": "intercom-id-fqdpw3fp",
              "value": "ea92200c-164d-428c-a67f-a2ef1a186b5b"
            },
            {
              "name": "intercom-device-id-fqdpw3fp",
              "value": "bb9651de-6ea8-4f8e-9f65-4786e457d97d"
            }
          ],
          "queryString": [],
          "headersSize": 624,
          "postData": {
            "mimeType": "application/json",
            "params": [],
            "text": "{\"hookInstance\":\"patient-view-ed2fe491-3eb7-424a-bf95-5d44b6102cec-1757217872349\",\"fhirServer\":\"http://localhost:8080/fhir\",\"hook\":\"patient-view\",\"context\":{\"patientId\":\"ed2fe491-3eb7-424a-bf95-5d44b6102cec\",\"userId\":\"Practitioner/example\"},\"prefetch\":{}}"
          }
        },
        "response": {
          "status": 500,
          "statusText": "Internal Server Error",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Access-Control-Allow-Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Vary",
              "value": "Origin"
            },
            {
              "name": "Content-Type",
              "value": "text/plain"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Keep-Alive",
              "value": "timeout=5"
            },
            {
              "name": "Transfer-Encoding",
              "value": "chunked"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "text/plain",
            "size": 0,
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 242,
          "bodySize": 1121
        },
        "cache": {},
        "timings": {
          "blocked": 0,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 2,
          "receive": 0
        },
        "time": 2,
        "_securityState": "insecure",
        "serverIPAddress": "::1",
        "connection": "5173",
        "pageref": "page_1"
      },
      {
        "startedDateTime": "2025-09-06T18:04:32.360-10:00",
        "request": {
          "bodySize": 0,
          "method": "OPTIONS",
          "url": "https://enhanced.hopena.info/fhir/Library/Hospice/$evaluate",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Host",
              "value": "enhanced.hopena.info"
            },
            {
              "name": "User-Agent",
              "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0"
            },
            {
              "name": "Accept",
              "value": "*/*"
            },
            {
              "name": "Accept-Language",
              "value": "en-US,en;q=0.5"
            },
            {
              "name": "Accept-Encoding",
              "value": "gzip, deflate, br, zstd"
            },
            {
              "name": "Access-Control-Request-Method",
              "value": "POST"
            },
            {
              "name": "Access-Control-Request-Headers",
              "value": "content-type"
            },
            {
              "name": "Referer",
              "value": "http://localhost:5173/"
            },
            {
              "name": "Origin",
              "value": "http://localhost:5173"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Sec-Fetch-Dest",
              "value": "empty"
            },
            {
              "name": "Sec-Fetch-Mode",
              "value": "cors"
            },
            {
              "name": "Sec-Fetch-Site",
              "value": "cross-site"
            },
            {
              "name": "Priority",
              "value": "u=4"
            }
          ],
          "cookies": [],
          "queryString": [],
          "headersSize": 525
        },
        "response": {
          "status": 204,
          "statusText": "No Content",
          "httpVersion": "HTTP/1.1",
          "headers": [
            {
              "name": "Server",
              "value": "nginx/1.24.0 (Ubuntu)"
            },
            {
              "name": "Date",
              "value": "Sun, 07 Sep 2025 04:04:32 GMT"
            },
            {
              "name": "Connection",
              "value": "keep-alive"
            },
            {
              "name": "Access-Control-Allow-Origin",
              "value": "https://cql-runner.dataphoria.org"
            },
            {
              "name": "Access-Control-Allow-Methods",
              "value": "GET, POST, PUT, DELETE, OPTIONS"
            },
            {
              "name": "Access-Control-Allow-Headers",
              "value": "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
            },
            {
              "name": "Access-Control-Max-Age",
              "value": "1728000"
            },
            {
              "name": "Content-Type",
              "value": "text/plain; charset=utf-8"
            },
            {
              "name": "Content-Length",
              "value": "0"
            }
          ],
          "cookies": [],
          "content": {
            "mimeType": "text/plain; charset=utf-8",
            "size": 0,
            "text": ""
          },
          "redirectURL": "",
          "headersSize": 467,
          "bodySize": 467
        },
        "cache": {},
        "timings": {
          "blocked": 195,
          "dns": 0,
          "connect": 0,
          "ssl": 0,
          "send": 0,
          "wait": 71,
          "receive": 0
        },
        "time": 266,
        "_securityState": "secure",
        "serverIPAddress": "45.61.61.124",
        "connection": "443",
        "pageref": "page_1"
      }
    ]
  }
}
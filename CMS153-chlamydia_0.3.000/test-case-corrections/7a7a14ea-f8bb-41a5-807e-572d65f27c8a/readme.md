There's a problem processing
```
define "Has Pregnancy Test Exclusion":
  exists ( ( ( ( [ServiceRequest: "Pregnancy Test"] ).isLaboratoryTestOrder ( ) ) PregnancyTest
        with ( ( [ServiceRequest: "XRay Study"] ).isDiagnosticStudyOrder ( ) ) XrayOrder
          such that XrayOrder.authoredOn.toInterval ( ) occurs 6 days or less on or after day of PregnancyTest.authoredOn.toInterval ( )
        where PregnancyTest.authoredOn.toInterval ( ) during "Measurement Period"
    )
      union ( ( [ServiceRequest: "Pregnancy Test"] ).isLaboratoryTestOrder ( ) ) PregnancyTestOrder
        with ( ( [MedicationRequest: "Isotretinoin"] ).isMedicationOrder ( ) ) AccutaneOrder
          such that AccutaneOrder.authoredOn.toInterval ( ) occurs 6 days or less on or after day of PregnancyTestOrder.authoredOn.toInterval ( )
        where PregnancyTestOrder.authoredOn.toInterval ( ) during "Measurement Period"
  )

```
We are looking at case 7a7a where the second part of the union is in effect. There is a ServiceRequest with authoredOn that initially equalled "2026-01-01T00:00:0.0000+00:00". The test passes when ( [ServiceRequest: "Pregnancy Test"] ).isLaboratoryTestOrder ( )  is run but fails when `where PregnancyTestOrder.authoredOn.toInterval ( ) during "Measurement Period"` is added. Now were are using Execute CQL in the working directory to determine what level of precision in authoredOn will flip the logic to true. 

|authoredOn|result|
|---|---|
|2026-01-01T00:00:00.000+00:00|false|
|2026-01-01T00:00:00+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T00:01:00+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T00:59:59+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T01:00:00+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T06:59:59+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T09:59:59+00:00|Has Pregnancy Test Exclusion=[]|
|2026-01-01T10:00:00+00:00|Has Pregnancy Test Exclusion=[ServiceRequest(id=08b3e886-c8b7-46f7-acc0-c8b653fab0f8)]|
|2026-01-01T11:59:59+00:00|Has Pregnancy Test Exclusion=[ServiceRequest(id=08b3e886-c8b7-46f7-acc0-c8b653fab0f8)]|
|2026-01-01T23:59:59+00:00|Has Pregnancy Test Exclusion=[ServiceRequest(id=08b3e886-c8b7-46f7-acc0-c8b653fab0f8)]|

OK, so it works funny on ExecuteCQL. But I updated the SR authoredOn to seconds precision and it seemed to pass OK on HAPI. 

What about just setting _precision_ to seconds in the CQL? 

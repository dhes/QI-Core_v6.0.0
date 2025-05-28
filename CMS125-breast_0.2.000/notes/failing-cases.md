# Failure of case 8278

This case fails DENEXPASS. The cause may be the "days" in 
```
      "dispenseRequest": {
        "expectedSupplyDuration": {
          "value": 90,
          "system": "http://unitsofmeasure.org",
          "code": "days"
        }
      }
```
because ucum uses 'd' not 'days'. Will modify bundle, redeploy resource and retest. 

## Summary

This test-case failure was more complicated than it initially appeared. The problem turned out to be a `convert ... to day` function call in the CumulativeMedicationDuration library. First, lets go back to the "code" in the above "expectedSupplyDuration". Changing it 'd' did not solve the problem, even though the change is correct. But a FHIRHeleprs routine implicitly (helpfully?) change 'd' back to 'day'. 
```
define function ToCalendarUnit(unit System.String):
    case unit
        when 'ms' then 'millisecond'
        when 's' then 'second'
        when 'min' then 'minute'
        when 'h' then 'hour'
        when 'd' then 'day'
        when 'wk' then 'week'
        when 'mo' then 'month'
        when 'a' then 'year'
        else unit
    end
```
Since the `convert` function expects UCUM units, it silently fails and the test passes. The proper solution might be to stop the implicit conversion. Since all of our test case MedicationRequests are in days, I chose the easy route an simple removed the convert function from the offending line in CumulateMedicationReport. 

Please note that I *did not* change the version number of the CMR library. Again, the easy route. 

As a result, those 5 of those 7 test cases pass, and the number of fails is down to 11. The still-failing cases are 5e3f and f38c. 

### 5e3f

This one has a condition-problem-health concern -- suspect the 'union problem'.

### f38c

This one throws an OperationOutcome error
```
{
      "resourceType": "OperationOutcome",
      "id": "ea0dee2c-3dc3-4a9b-b648-a8c3f6f17d3e",
      "issue": [
        {
          "severity": "error",
          "code": "exception",
          "diagnostics": "Exception for subjectId: Patient/f38ce16a-658f-4aa0-b4a6-fac61d2e58a8, Message: Invalid Interval - the ending boundary must be greater than or equal to the starting boundary."
        }
      ]
    }
```
possible related to this MedicationRequest period
```
      "effectivePeriod": {
        "start": "2026-12-31T00:00:00.000+00:00",
        "end": "2026-01-01T00:00:00.000+00:00"
      }
```
#### Solution
```
      "effectivePeriod": {
        "start": "2026-01-01T00:00:00.000+00:00",
        "end": "2026-12-31T00:00:00.000+00:00"
      }
```
Replaced in all files; updated server resource. 

### 847f

This case has procedures with edge-case periods
```
      "performedPeriod": {
        "start": "2026-12-31T23:59:59.000+00:00",
        "end": "2026-12-31T23:59:59.000+00:00"
      }
```
that eventually encounters the logic
```
where UnilateralMastectomyRightPerformed.performed.toInterval ( ) ends on or before end of "Measurement Period"
```

#### The Question
So the question is -- what sort of surprises do we get if we run the performedPeriod -- (presumably) Interval[@2026-12-31T23:59:59.000+00:00,@2026-12-31T23:59:59.000+00:00] -- through 'on or before end of ..' with different granularity forms of "Measurement Period" e.g. [@2026-01-31,@2026-12-31] vs the most granular form. First to understand is that the most granular allowed form of those in the $evaluate-measure API call on HAPI is [@2026-01-01T00:00:00, @2026-12-31T23:59:59] meaning *fractions of seconds* are not allowed. So these Procedure resources amount to edge test cases of IntervalA *some function* IntervalB where the granularity of IntervalB is less than Interval A. 

#### Looking for answers in Execute CQL. 

In this CQL code
```
parameter "Measurement Period" Interval<DateTime> default Interval[@2026-01-01T00:00:00.000+00:00, @2026-12-31T23:59:59.000+00:00]

context Patient

define  AMeasurementPeriod: "Measurement Period"
define APeriodEndsOnOrBeforeMeasurementPeriod: Interval[@2026-12-31T23:59:59.000+00:00,@2026-12-31T23:59:59.999+00:00] ends on or before end of "Measurement Period"
```

we've represented the start and end of performedPeriod with the interval that would represent it, down to the millisecond. Next we've selected a granularity for measurementPeriod (MP) -- in this case a granularity that matches performedPeriod and *which HAPI will not allow* -- just to see how the CQL engine treats it. From there we can dial down the granularity in steps, to see where it might flip from true to false. 

These key phrases are from [CQL reference guide](https://cql.hl7.org/09-b-cqlreference.html#same-or-before-2) ('Same Or Before' is the same as 'On or Before')


 - When this operator is called with a mixture of point values and intervals, the point values are implicitly converted to an interval starting and ending on the given point value.
 - If no precision is specified, comparisons are performed beginning with years (or hours for time values) and proceeding to the finest precision specified in either input.
 - For DateTime values, precision must be one of: year, month, day, hour, minute, second, or millisecond.
 - The same-precision-or before operator compares two Date, DateTime, or Time values to the specified precision to determine whether the first argument is the same or before the second argument. The comparison is performed by considering each precision in order, beginning with years (or hours for time values). If the values are the same, comparison proceeds to the next precision; if the first value is less than the second, the result is true; if the first value is greater than the second, the result is false; if either input has no value for the precision, the comparison stops and the result is null; if the specified precision has been reached, the comparison stops and the result is true.
`

So in our case *performedPeriod* is transformed to a *date* by 'ends' and then is transformed back to the the same Interval it started out to be. Also, one assumes that CQL will ramp up the precision until it gets to *second*, because that's as far as it goes. 

So the upshot of all of this is that edge cases with millisecond precision that occur at the very last second of the measurement period will fail. It's like asking `is 2026-12-31 on or before 2026-12`. The fix was to demote the precision of `performedProcedure` to seconds
```
  "performedPeriod": {
    "start": "2026-12-31T23:59:59+00:00",
    "end": "2026-12-31T23:59:59+00:00"
  }
```

The will work for `periodStart=2026&periodEnd=2026` `periodStart=2026-01-01&periodEnd=2026-12-31` and `periodStart=2026-01-01T00:00:00&periodEnd=2026-12-31T23:59:59` because HAPI FHIR always coerces imprecise dateTime to the latest second. 

Parting thoughts -- CQL allows a hard coded millisecond-precision "Measurement Period" parameter. If the $evaluate-measure operator has no startPeriod/endPeriod, the CQL *should* default to this higher precision value. In that case the test-cases with overly-precisce procedure.performedPeriod(s) might actually pass. Gotcha!

### 73f7 - resolved
This look like the familiar PalliativeCare case, where a Condition union Condition fails in the PalliativeCare Library. This passes with PalliativeCare .001

Since .001 PalliativeCare and Hospice, these are the remaining failures. 
### 4cf8 - resolved
bilateral mastectomy procedure with date .000 precision
Passes after milliseconds removed from resource. 
### 4827 - resolved
history of mastectomy problem-list-item Condition x 2 with onset .000 precision
Resolved after adding aliases to Left and Right Mastectomy Diagnosis identifiers.  

### 4fa2 - resolved
condition bilateral mastectomy dated end of year .000
This one is described as "Patient 52yo w/ an Office Visit  Encounter 1/1 of the MP & Bilateral Mastectomy Dx that starts on 12/31 of the MP." but the actual dateTime in the condition is 12/31 of the previous year. Deployed updated resource. 
Still fails. Oops, gotta fix 
define "Bilateral Mastectomy Diagnosis":
  ( ( ( [ConditionEncounterDiagnosis: "History of bilateral mastectomy"] )
      union ( [ConditionProblemsHealthConcerns: "History of bilateral mastectomy"] ) ) BilateralMastectomyHistory
      where BilateralMastectomyHistory.prevalenceInterval ( ) starts on or before end of "Measurement Period"
  )

### 5e3f
frailty condition onset last second of year with .000

### 2886
hospice discharge encounter that lasts one second with .000 precision
```
{
        "start": "2025-12-31T23:59:59.000+00:00",
        "end": "2026-01-01T01:00:00.000+00:00"
      }
```
### 6290 - resolved
advance illness with Condition onset 2025-01-01T00:00:00.000+00:00
has .000 precision in an Encounter and Condition
Updated date. 
will need to fix 
```
(([ConditionProblemsHealthConcerns: "Frailty Diagnosis"])
    union ([ConditionEncounterDiagnosis: "Frailty Diagnosis"]))
```
and
```
([ConditionProblemsHealthConcerns: "Advanced Illness"])
union ([ConditionEncounterDiagnosis: "Advanced Illness"])
```
change Frailty Library version # in main and post the new Frailty Library. 

### 7e5d - resolved
Encounter lasting .000 sec
Absence of breast L and R dated 2026-01-01T00:00:00.000+00:00


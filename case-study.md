|{patientId}|"Initial Population"|"Denominator"|"Numerator"|"Denominator Exclusions"|"Denominator Exceptions"|measureScore|
|---|---|---|---|---|---|---|
|raw CQL|||||||
|HAPI measure-population|||||||
|fqm measure population|||||||
|MADiE test case |||||||

Note: identifiers from CQL are carried forward to MeasureReport.group.population items as "Family Doctor" => res-ipsa. For example "Initial Population"=> initial-population

# TODO - fix the denominator exclusion and exception discussion

# Case presentation

This refers to case #62 listed on MADiE for *Preventive Care and Screening: Body Mass Index (BMI) Screening and Follow-Up PlanFHIR QI Core 6.0.0*. The local file is [here](CMS69-bmi_0.3.000/test-cases/5d34e56e-f4f1-4817-b7e4-e4c57f811300/CMS69FHIR-v0.3.000-DENEXPass-ConditionPalliativeCare.json) and it's fqm raw cql output is [here](output/cql-raw/5d34e56e-f4f1-4817-b7e4-e4c57f811300.json). These test cases all run for the 2026 measurement period. 

## The CQL

First we'll walk through the CQL as applied to this patient. We'll take it in the order that it appears in the CQL. 

The "Initial Population" in CQL for this measure is
```
define "Initial Population":
  exists "Qualifying Encounter During Day Of Measurement Period" QualifyingEncounter
    where "AgeInYearsAt"(date from start of QualifyingEncounter.period) >= 18
```

This patient had an Encounter on 2026-01-01 that meets the criteria for a Qualifying Encounter, so she passes 'exists "Qualifying Encounter During Day Of Measurement Period"'. Her birthday is 2001-01-01 which makes her 25 years old on 2026-01-01, so she meets the age criteria. That gets her past the "Initial Population". 

"Denominator" is equal to "Initial Population"
```
define "Denominator":
  "Initial Population"
```
 so she passes "Denominator". 

Next is 

```
define "Denominator Exclusions":
  Hospice."Has Hospice Services"
    or PalliativeCare."Has Palliative Care in the Measurement Period"
    or exists "Is Pregnant During Day Of Measurement Period"
```

There is no record of Hospice or pregnancy in her chart (although oddly her test case given name is "Pregnant"). However, she has a Condition resource categorized as an encounter diagnosis, coded as Snomed CT 441874000 "Seen by palliative care service (finding)". This Encounter code qualifies her for "Has Palliative Care in the Measurement Period", and she is therefore eligible for "Denominator Exclusions". 

```
"Denominator Exclusions": true
```

Next we come to  "Numerator"
```
define "Numerator":
  exists "High BMI And Follow Up Provided"
    or exists "Low BMI And Follow Up Provided"
    or "Has Normal BMI"
```

Looking through her chart for Observation resources, we find that she has none. So no luck with the BMIs and no luck with "Numerator".

```
"Numerator": false
```

Finally we have "Denominator Exceptions".

```
define "Denominator Exceptions":
  exists "Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI"
    or exists "Medical Reason Or Patient Reason For Not Performing BMI Exam"

```

There is nothing in her chart to suggest either of these, so we have

```
"Denominator Exceptions": false
```

"Numerator Exclusion" is not mentioned for this Measure, so it's not interesting, so we'll leave it out. 

Summarizing: 

|Test Case #62|"Initial Population"|"Denominator"|"Denominator Exclusions"|"Numerator"|"Denominator Exceptions"|measureScore|
|-------------|:------------------:|:-----------:|:----------------------:|:---------:|:----------------------:|:----------:|
|raw CQL      |true                |true         |true                    |false      |false                   |?           |

measureScore we haven't talked about yet, so we'll mark it as ? for now. 

So far I've presented the CQL in the order that it appears in code, but I'm going to switch the to something that feels more natural to me. 

|Test Case #62|"Initial Population"|"Denominator"|"Denominator Exclusions"|"Denominator Exceptions"|"Numerator"|measureScore|
|-------------|:------------------:|:-----------:|:----------------------:|:----------------------:|:---------:|:----------:|
|raw CQL      |true                |true         |true                    |false                   |false      |?           |

We've completed our journey through the first BMI test case. We don't yet know how the patient scored. What is the next step? 

## The Measure Report

FHIR translates from CQL to MeasureReport by way of the Measure resource. The relevant portion of the Resource look like this, in our case. 

```json
"population": [
  {
    "id": "InitialPopulation_1",
    "code": {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/measure-population",
          "code": **"initial-population"**,
          "display": "Initial Population"
        }
      ]
    },
    "description": "All patients aged 18 and older on the date of the encounter with at least one qualifying encounter during the measurement period",
    "criteria": {
      "language": "text/cql-identifier",
      "expression": **"Initial Population"**
    }
  },
...]
```

Take note of `"expression": "Initial Population"` and `"code": "initial-population"`. This element carries forward the CQL "Initial Population" into the *initial-population* population of the *measure-population* code system. 

When you process the test case, it evaluates the CQL and reports the results to a FHIR MeasureReport. The relevant data would look like this. 

```json
"population": [ {
  "id": "InitialPopulation_1",
  "code": {
    "coding": [ {
      "system": "http://terminology.hl7.org/CodeSystem/measure-population",
      "code": "initial-population",
      "display": "Initial Population"
    } ]
  },
  "count": 1
}
...]
```
You will notice here that instead of a Boolean we have a count. We should take a step back for a second. Population Measures always return values for a group of patients. When you calculate a score for a population, you aggregate the result of all of the individuals in the population. These results can often be represented by a fraction or ratio
```
measureScore = n / m
```
but *not always*. At this point we are evaluating a score for a single person -- which actually would be the case as the case of a population of 1. In the process of going from CQL to MeasureReport counts, you translate from Boolean to Binary. 

|Boolean|Binary|
|---|---|
|true|1|
|false|0|

This makes it convenient to sum up individual results into a population result. That is why you see a "count" of instead of a "valueBoolean" of true. 

For brevity I've only provided details for "Initial Population", but all the remaining CQL identifiers and their corresponding population counts follow the same pattern. So carrying that forward into our summary data for Test Patient #62, we have:

|Test Case #62                 |"Initial Population"|"Denominator"|"Denominator Exclusions"|"Denominator Exceptions"|"Numerator"|measureScore|
|------------------------------|:------------------:|:-----------:|:----------------------:|:----------------------:|:---------:|:----------:|
|raw CQL                       |true                |true         |true                    |false                   |false      |NA           |
|MeasureReport population count|1                   |1            |1                       |0                       |0          |NA           |

where NA stands for 'Not applicable'. MeasureScore is NA so far because it is not calculated in the CQL. 

## The Score - that's the rub

All of the fuss has a simple purpose. When something was supposed to be done, how often was it done? That's what the score is for. If you carefully examine the CQL and the Measure library for this Measure, you may be surprised to find that the method for calculating the Score is not defined. For that you have to turn to CMS documents for the Measure itself, and to CMS document the outline methods of calculations. There are different types of measure, of which this BMI example is called a *Proportion* measure. This means basically what you might think - the proportion, or ration,  of the count of patients who had something done compared to those who were supposed to have something done (according to the Measure). You might be thinking about using a fraction for that, which *usually* works with a large popuation, but we'll have to think this through a little first. What about an individual case? Not much to add up here! At this *atomic* level the thinking is a little different. You are asking *was this patient supposed to have something done?* and *was it done?*, so these are Boolean questions. That reflects the values in our table (so far). So if we're thinking Boolean the possibilities might be

|supposed to be done|actually done|
|---|---|
|1|1|
|1|0|
|0|1|
|0|0|

There is one thing I should mention -- the value of 'actually done' is constrained by 'supposed to be done'. You don't care if it was or was not 'actually done' in a patient in whom it was not 'supposed to be done'. So that limits us to 

|supposed to be done|actually done|
|---|---|
|1|1|
|1|0|
|0|0|

Which could be represented by fractions

|supposed to be done|actually done|fraction|
|---|---|---|
|1|1|1/1|
|1|0|0/1|
|0|0|0/0|

But uh oh -- we're stuck, because 0/0 is not defined. So you can't use a fraction for that case. So what to do? Thinking back on the meaning of "0/0", this is a patient in whom something 'was not supposed to be done' and 'was not done'. Do we care? That's the rub in the Score calculation, and the source of some problems in Score calculation implementations. 

## How does FHIR data actually get processed

### HAPI FHIR 

HAPI FHIR is a widely used open source FHIR server, which includes function to create MeasureScore. I won't go into detail here, except to say that is has been around a long time and is widely used. 

### fqm-execution

fqm-execution is also open source, and is employed in the processing of test cases at the MADiE repository. I've mentioned MADiE before as the source of our Case Study. I won't to into much more detail regarding MADiE either, except to say that it is widely used and had become key in the evolution of CMS Performance Measures. 

Anyone with sufficient interest and technical knowledge can download HAPI and fqm onto their computer and use them to process Measure test cases such as the one we are examining here. The next two tranches of data that I present to you are the results of the process. 

Getting straight to the data -- if you process Test Case #62 with HAPI, you get seen in the third line. We also will for the first time see a Measure Score for our patient (sort of...).

|Test Case #62                 |"Initial Population"|"Denominator"|"Denominator Exclusions"|"Denominator Exceptions"|"Numerator"|measureScore|
|------------------------------|:------------------:|:-----------:|:----------------------:|:----------------------:|:---------:|:----------:|
|raw CQL                       |true                |true         |true                    |false                   |false      |NA           |
|MeasureReport population count|1                   |1            |1                       |0                       |0          |NA           |
|HAPI Calculation              |1                   |0            |1                       |0                       |0          |NC           |

where NC stands for 'Not Counted'. It is not counted because a patient is not counted if they are not in "The Denominator". 

This is where the terminology need clarification. The term is used in two different ways. You may recall that there is a CQL "Denominator" definition. That's one. We discussed above how you might represent a score for a population of more than one patients as 
```
measureScore = actually done / should have been done
```

meaning a count of the patients how had something done / a count of the patients in whom it should have been done. In our test case because the patient was excluded from the 'should have been done' population there is no score i.e. the patient is 'Not Counted'. 

Now here's the rub with HAPI. You may notice that the "Denominator" column when from 'true' to '1' (another way to say 'true'), *but then to '0' in the HAPI column. That is because apparently HAPI reports the 'should have been done' count instead of faithfully passing on the value from the CQL calculation. The the patient has a "Denominator Exclusion" and the actual logic for calculating a single person score is 

```
 "Numerator" / "Initial Population" AND "Denominator" AND NOT ("Denominator Exclusions" OR "Denominator Exceptions")
```

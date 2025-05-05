Review my discussion with ChatGPT named HAPI 8.0.0-v2 discrepancy analysis. 
## The Problem

See [this code](https://github.com/cqframework/clinical-reasoning/blob/master/cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/measure/common/MeasureEvaluator.java) from HAPI repo to view measureScore calculation. Pay special attention to the code 
```
...
numerator.getSubjects().retainAll(denominator.getSubjects());
numerator.getResources().retainAll(denominator.getResources());
...
denominator.getResources().retainAll(initialPopulation.getResources());
denominator.getSubjects().retainAll(initialPopulation.getSubjects());
...
denominatorExclusion.getResources().retainAll(denominator.getResources());
denominatorExclusion.getSubjects().retainAll(denominator.getSubjects());
...
denominatorException.getSubjects().removeAll(numerator.getSubjects());
denominatorException.getResources().removeAll(numerator.getResources());
...
denominatorException.getResources().retainAll(denominator.getResources());
denominatorException.getSubjects().retainAll(denominator.getSubjects());
...
```
and Similar logic for Numerator Exclusion.. 

See the ChatGPT session name 'HAPI 8.0.0-v2 discrepancy analysis'. Look to the very end for a walkthrough of the filtering, and view the lines of code reviewed. Its conclusion:

"The scorer uses this helper:
```
getCountFromGroupPopulation(mrgc.getPopulation(), NUMERATOR_EXCLUSION)
```
And here’s its code:
```
return populations.stream()
    .filter(population -> populationName.equals(
        population.getCode().getCodingFirstRep().getCode()))
    .map(MeasureReportGroupPopulationComponent::getCount)
    .findAny()
    .orElse(0);
```
💥 Problem: If numerator-exclusion is not present at all in the population[] list, getCountFromGroupPopulation(...) might return null, and you’d get a NullPointerException, OR it could misbehave when doing subtraction."

## The Likely Cause

Inspecting the unaltered Measure as download, and searching for the term 'inverse', look what we find in Measure.group[0].extenion[4]
```
"url": "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-improvementNotation",
"valueCodeableConcept": {
  "coding": [ {
    "system": "http://terminology.hl7.org/CodeSystem/measure-improvement-notation",
    "code": "decrease",
    "display": "increase"
  }
]}
```
Now, here ye, at least as early as R4, Measure has an .improvementNotation element as so
```
 improvementNotation 	Σ	0..1	CodeableConcept	increase | decrease
Binding: Measure Improvement Notation (Required)
```
Said element is NOT present in the CMS69-bmi measure, but as you can see an apparent group-level extension which appears to have the same effect. (You also note that the "code" and "display" elements do not match, likely a cut and paste error). 

So that is a very likely suspect for the culprit. 

Almost forgot -- here is the code in R4MeasureReportScorer.java in the cqframework/clinical-reasoning repo
```
        switch (measureScoring) {
            case PROPORTION:
            case RATIO:
                var score = calcProportionScore(
                        getCountFromGroupPopulation(mrgc.getPopulation(), NUMERATOR)
                                - getCountFromGroupPopulation(mrgc.getPopulation(), NUMERATOR_EXCLUSION),
                        getCountFromGroupPopulation(mrgc.getPopulation(), DENOMINATOR)
                                - getCountFromGroupPopulation(mrgc.getPopulation(), DENOMINATOR_EXCLUSION)
                                - getCountFromGroupPopulation(mrgc.getPopulation(), DENOMINATOR_EXCEPTION));
                if (score != null) {
                    if (isIncreaseImprovementNotation) {
                        mrgc.setMeasureScore(new Quantity(score));
                    } else {
                        mrgc.setMeasureScore(new Quantity(1 - score));
                    }
                }
                break;
            default:
                break;
        }
```
Pay special attention to these line.
```
...
                if (score != null) {
                    if (isIncreaseImprovementNotation) {
                        mrgc.setMeasureScore(new Quantity(score));
                    } else {
                        mrgc.setMeasureScore(new Quantity(1 - score));
                    }
                }
...
```
Presumably `isIncreaseImprovementNotation` is reading from the Measure.group.extension. One wonders if it could also read from Measure.improvementNotation if supplied. Also one wonders about the code of `isIncreaseImprovementNotation` especiallly its default behavior. 

Here is a snippet which may be the definition of `isImprovementNotation`, from     clinical-reasoning/cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/measure/common
/GroupDef.java. 
```
public boolean isIncreaseImprovementNotation() {
        if (getImprovementNotation() != null) {
            return getImprovementNotation().code().equals("increase");
        } else {
            // default response if null
            return true;
        }
    }
```

It appears to default to true, which would suggest that HAPI *is* reading the measure-improvement-notation in Measure.group.extension. 

## Watch out Road, here comes the Rubber

So, how to fix? A few different options come to mind. 
1) correct the code in the group extension. 
2) add the code as a improvementNotation element. 
3) both

Hopefully by checking all of these we can determine where HAPI is reading We'll start with the simplest. As a test we will rerun case 296d38e4-d69b-481e-a8cf-f7eee8b9e5d7/CMS69FHIR-v0.3.000-IPPPass-Age18HasEnc.json. At present -- with the CMS69-bmi Measure unchanged, running 
```
GET Measure/CMS69FHIRPCSBMIScreenAndFollowUp/$evaluate-measure?subject=Patient/296d38e4-d69b-481e-a8cf-f7eee8b9e5d7&periodStart=2026&periodEnd=2026
```
returns counts 
```
"initial-population":  1
"denominator": 1
"denominator-exclusion": 0
"numerator": 0
"denominator-exception": 0
```
and measureScore
```
"measureScore": 1.0
```
which appears *inverted*. 

### Option 1 update the group extension

Proposal: Change the group measure-improvement-notation element from
```
      "url": "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-improvementNotation",
      "valueCodeableConcept": {
        "coding": [ {
          "system": "http://terminology.hl7.org/CodeSystem/measure-improvement-notation",
          "code": "decrease",
          "display": "increase"
        }]}
```
to
```

      "url": "http://hl7.org/fhir/us/cqfmeasures/StructureDefinition/cqfm-improvementNotation",
      "valueCodeableConcept": {
        "coding": [ {
          "system": "http://terminology.hl7.org/CodeSystem/measure-improvement-notation",
          "code": "increase",
          "display": "increase"
        }]}

```
and rerun the $evaluate-measure call. 

Result:
Counts:
```

```
measureScore
```

```

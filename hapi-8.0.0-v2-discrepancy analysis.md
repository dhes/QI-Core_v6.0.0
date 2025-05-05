Review my discussion with ChatGPT named HAPI 8.0.0-v2 discrepancy analysis. 

See [this code](https://raw.githubusercontent.com/cqframework/clinical-reasoning/refs/heads/master/cqf-fhir-cr/src/main/java/org/opencds/cqf/fhir/cr/measure/common/MeasureEvaluator.java) from HAPI repo to view measureScore calculation. Pay special attention to the code 
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

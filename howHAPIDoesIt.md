Key snippet from clinical-reasoning-master directory. BaseMeasureReportScorer.java
```java 
package org.opencds.cqf.fhir.cr.measure.common;

public abstract class BaseMeasureReportScorer<MeasureReportT> implements MeasureReportScorer<MeasureReportT> {
    protected Double calcProportionScore(Integer numeratorCount, Integer denominatorCount) {
        if (numeratorCount == null) {
            numeratorCount = 0;
        }
        if (denominatorCount != null && denominatorCount != 0) {
            return numeratorCount / (double) denominatorCount;
        }

        return null;
    }
}
```

Now if I could just find where cql measure-population|denominator gets assigned. It might be in MeasureEvaluator.java. 

##Here it is!

Look in MeasureEvaluator.java in the clinical-reasoning-master directory for things like 
```
        initialPopulation = evaluatePopulationMembership(subjectType, subjectId, initialPopulation, evaluationResult);

        if (initialPopulation.getSubjects().contains(subjectId)) {
            // Evaluate Population Expressions
            denominator = evaluatePopulationMembership(subjectType, subjectId, denominator, evaluationResult);
            numerator = evaluatePopulationMembership(subjectType, subjectId, numerator, evaluationResult);

...
```
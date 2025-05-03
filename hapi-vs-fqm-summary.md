This summary assumes familiarity with a Logical Pipeline with Irreversible Pruning model. 

I'd like to step back a bit, thank you. We are undertaking this discussion to see if the methodology in fqm, HAPI $evaluate-measure and this CMS document are in full alignment. There are two dimension to this conclusion -- the reported measure-population results in the MeasureReport (initial-population, denominator, denominator-exclusion, denominator-exception, numerator, numerator-exclusion); and the reported measureScore. The first case my findings are 
```
- fqm reports denominator as DENOM. In many measure the cql defines "Denominator" = "Initial Population" so in the MeasureReport they are always, ....well...., equal. 
- fql uses the expression  ' // (Numerator - Numerator Exclusions) / (Denominator - D Exclusions - D Exceptions).'  to calculate the *Performance rate* (this is a comment cut and pasted directly from code and is verified in test-case batch runs)
- fqm reports denominator-exception as 0 if "Denominator Exclusion" = 1 and "Denominator Exception" = 1. This reflect the logical filtering that needs to occur if the above *Performance rate* is going to be used. 
- fqm reports measureScore as 0 or 1. It reports {Considered = 0, Qualified = 0} as 0. 0 actually represents two possible values. 
- fqm is the back-end of MADiE, but the MADiE test case individual MeasureReport.group.population.measureScores are never {null}, at least for all 62 BMI test cases. They follow no discernable pattern and probably need review. 
- since there is no NUMEX in CMS69-bmi, one can inspect the MeasureReport output and infer the measureScore using *numeratore*/(*denominator* - (*denominator exclusion* OR *denominator exception*))
- in its current state the expected and actual measureScore are incongruent half the time when run through fqm
- HAPI reports the *denominator* as Considered i.e. the value of the measureScore denominator. Since *initial-population* alway equals *denominator*, no information is lost. 
- I have yet to test if HAPI reports both "Denominator Exclusion" = 1 and "Denominator Exception" = 1 faithfully
- HAPI reports measureScore as 1 (Considered = 1, Qualified = 1), 0 (Considered = 1, Qualified = 0) or null (Considered = 0, Qualified = 0), so the information in the measureScore value complete and can be used in the population score. 
- This makes it relatively easy for a human to deduce the measureScore from the indivual score tuple by simple inspection. 

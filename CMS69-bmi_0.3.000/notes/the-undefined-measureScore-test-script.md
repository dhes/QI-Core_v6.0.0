When the "total denominator" of the population score of a single patient is zero then the measureScore is undefined. HAPI deals with that case by omitting the measureScore key from the MeasureReport. Here is the corresponding test case line
```
tc.test("Measure Score is absent", json.group[0]?.measureScore === undefined);
```
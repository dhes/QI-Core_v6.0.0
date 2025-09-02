#!/bin/bash
echo "Comparing Measure logic vs. PlanDefinition logic..."
for pd_output in $(find ./measures -path '*-pd/output.json'); do
  measure_dir=$(dirname "$pd_output")
  baseline_output="${measure_dir%-pd}/output.json"
  echo "Comparing $pd_output to $baseline_output"
  node ./scripts/compare-outputs.js "$baseline_output" "$pd_output"
done
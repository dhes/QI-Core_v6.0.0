jq '{
    "Initial Population": .group[0].population[] | select(.id == "InitialPopulation_1") | .count,
    "Denominator 1": .group[0].population[] | select(.id == "Denominator_1") | .count,
    "Denominator 2": .group[1].population[] | select(.id == "Denominator_2") | .count,
    "Denominator 3": .group[2].population[] | select(.id == "Denominator_3") | .count,
    "Denominator Exclusion": .group[0].population[] | select(.id == "DenominatorExclusion_1") | .count,
    "Numerator 1": .group[0].population[] | select(.id == "Numerator_1") | .count,
    "Numerator 2": .group[1].population[] | select(.id == "Numerator_2") | .count,
    "Numerator 3": .group[2].population[] | select(.id == "Numerator_3") | .count,
    "Patient Score 1": .group[0].measureScore.value,
    "Patient Score 2": .group[1].measureScore.value,
    "Patient Score 3": .group[2].measureScore.value
  }' input/tests/measure/CMS138FHIRPreventiveTobaccoCessation/0a82b597-2959-4b36-b922-a7025a6110eb/MeasureReport/ba085a6e-586a-4536-9907-9dabc21b8b45.json
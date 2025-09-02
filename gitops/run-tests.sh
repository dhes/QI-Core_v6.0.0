#!/bin/bash
echo "Running tests with fqm-execution..."
for bundle in $(find ./measures -name '*patient-bundle.json'); do
  measure_dir=$(dirname "$bundle")
  node ./node_modules/.bin/fqm-execution \
    --elm $measure_dir/*.elm.json \
    --bundle $bundle \
    --measure-id "$(basename $measure_dir)" \
    --output $measure_dir/output.json
done
#!/bin/bash
echo "Translating all CQL files to ELM..."
for file in $(find ./measures -name '*.cql'); do
  echo "Translating $file"
  curl -X POST http://localhost:8080/cql/translator -H "Content-Type: text/cql" --data-binary "@$file" -o "${file%.cql}.elm.json"
done
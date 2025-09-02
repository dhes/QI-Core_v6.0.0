# GitOps for Clinical Logic

This repository supports GitOps-based authoring, testing, and deployment of CQL-based clinical logic. It includes:

- Forkable CQL measures and PlanDefinition variants
- Automated translation to ELM
- Local testing with fqm-execution
- GitHub Actions to validate and compare outputs

## Project Structure

<pre>
├── measures/
│   └── CMS138-tobacco/
│       ├── cql/
│       │   ├── Measure.cql
│       │   └── PlanDefinition.cql
│       ├── fhir/
│       │   ├── PlanDefinition.json
│       │   └── Library.json
│       └── test-bundles/
│           └── patient-001/
│               └── patient-bundle.json
├── scripts/
│   ├── translate-cql.sh
│   ├── run-tests.sh
│   ├── compare-measure-vs-pd.sh
│   └── compare-outputs.js
└── .github/
    └── workflows/
        └── validate-and-deploy.yml
</pre>

## Workflow

1. Modify or fork a measure (e.g. create a PlanDefinition version).
2. Commit changes and push a branch.
3. Open a pull request.
4. GitHub Actions will:
   - Translate CQL
   - Run tests using fqm-execution
   - Compare outputs to the baseline measure
5. If all checks pass, merge to `main`.

## Local Dev Tips

- Run `translate-cql.sh` to convert all `.cql` to `.elm.json`
- Run `run-tests.sh` to execute logic on test bundles
- Use `compare-measure-vs-pd.sh` to detect logic divergence

## License

MIT License
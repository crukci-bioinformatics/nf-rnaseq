# Test fixtures

Placeholder inputs for `-profile test`, used to exercise the whole pipeline graph in
seconds with no container, no real reference data and no real FASTQ content:

```
nextflow run rnaseq.nf -stub-run -profile test
```

Must be run from the repository root — the paths in `alignment.csv`, `samplesheet.csv`
and `contrasts.csv` are relative to the launch directory, not `projectDir`.

## What this covers

- Two samples: `sampleA` split across two lanes (exercises the `groupTuple` merge in
  `rnaseq.nf`), `sampleB` with a single lane.
- `data/` holds empty, correctly-named FASTQ files so the sample-sheet and kickstart-CSV
  existence checks (`checkIfExists:true`) pass.
- `resources/` holds an empty salmon index directory and empty `tx2gene`/GTF files.
  These are placeholders — the `test` profile only ever runs with `-stub-run`, which
  never reads process inputs, so their content is never exercised.

## What this does not cover

Stub outputs are empty. This profile is a syntax/graph regression check (does the
pipeline still wire together the same way — same task count, same published files) —
not a check that quantification or the DESeq2 report are scientifically correct.

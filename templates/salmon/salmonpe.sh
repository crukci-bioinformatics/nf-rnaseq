#!/bin/bash

set -o pipefail

!{params.salmon_path} \
    quant \
    --threads !{Math.max(1, task.cpus - 1)} \
    -l A \
    --gcBias \
    --index !{index} \
    -1 !{r1_fqs} \
    -2 !{r2_fqs} \
    --output !{sample_name}

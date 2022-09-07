#!/bin/bash

set -o pipefail

Rscript runRNAseqReport.R \
    --projectName=!{projectName} \
    --sampleSheet=!{sampleSheet} \
    --genome=!{genome} \
    --assembly=!{assembly} \
    --quantOutDir==!{quantOutDir} \
    --tx2geneFile=!{tx2gene} \
    --gtfFile=!{} \
    --contrastFile=!{contrastFile} \
    --design=!{design} \
    --countsDir=!{} \
    --colorFactorNames=!{} \
    --DeOutDir=!{} \
    --pValCutoff=!{} \
    --genesToShow=!{} \
    --templateDir=!{} \
    --reportFile=!{}


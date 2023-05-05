#!/bin/bash

set -o pipefail

Rscript bin/runRNAseqReport.R \
    --project=!{projectName} \
    --samplesheet=!{sampleSheet} \
    --genome=!{genome} \
    --assembly=!{assembly} \
    --quantOut==!{quantOutDir} \
    --tx2geneFile=!{tx2gene} \
    --gtfFile=!{gtfFile} \
    --contrastFile=!{contrastFile} \
    --design=!{design} \
    --countsDir=!{countsDir} \
    --factorName=!{colorFactors} \
    --DeOutDir=!{DeOutDir} \
    --pValCutoff=!{pValCutoff} \
    --genesToShow=!{genesToShow} \
    --templateDir=!{templateDir} 


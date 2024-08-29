#!/bin/bash

set -o pipefail

Rscript bin/runRNAseqReport.R \
    --project=!{projectName} \
    --samplesheet=!{sampleSheet} \
    --species=!{species} \
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
    --reportFile=!{reportFile} \
    --templateDir=!{templateDir} 


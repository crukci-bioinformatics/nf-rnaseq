#!/usr/bin/env nextflow

/*
 * Main rnaseq work flow.
 */

nextflow.enable.dsl = 2

include { checkParameters; checkKickstartCSV; displayParameters } from "./components/configuration"

// Check all is well with the parameters and the alignment.csv file.

if (!checkParameters(params))
{
    exit 1
}
if (!checkKickstartCSV(params))
{
    exit 1
}
if (!checkRNAseqSampleSheet(params))
{
    exit 1
}


switch (params.quantTool)
{
    case 'salmon':
        if (params.pairedEnd)
        {
            include { salmon_pe as quantification } from "./pipelines/salmon_pe"
        }
        else
        {
            exit 1, "rnaseq pipeline currently supports paired-end data"
        }
        break

    default:
        exit 1, "rnaseq pipeline currently supports only salmon"
}

displayParameters(params)


/*
 * Main work flow. For each sample in alignment.csv, start quantifying.
 */
workflow
{
    csv_channel = channel
        .fromPath(params.kickstartCSV)
        .splitCsv(header: true, quote: '"', strip: true)

    quantification(csv_channel)
}
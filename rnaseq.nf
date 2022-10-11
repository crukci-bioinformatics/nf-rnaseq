#!/usr/bin/env nextflow

/*
 * Main rnaseq work flow.
 */

nextflow.enable.dsl = 2

def wrap_items(input_files) {
  def result =  input_files instanceof Path ? input_files.toString() : (input_files as List).join('", "')
  return '"'+result+'"'
}

include { checkParameters; checkKickstartCSV; displayParameters; checkRNAseqSampleSheet; checkRNAseqContrastFile  } from "./components/configuration"

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
if (!checkRNAseqContrastFile(params))
{
    exit 1
}

switch (params.quantTool)
{
    case 'salmon':
        if (params.pairedEnd)
        {
            include { SALMON } from "./processes/salmon"
            include { RNASEQREPORT } from "./processes/rnaseqreportprocess"
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
 * Finally generate a RNAseq report
 */

workflow
{ 
    csv_channel = channel
        .fromPath(params.kickstartCSV)
        .splitCsv(header: true, quote: '"', strip: true) 
        .map(row -> tuple "${row.SampleName}", file("${params.fastqDir}/${row.Read1}", checkIfExists:true), file("${params.fastqDir}/${row.Read2}", checkIfExists:true) )
        .groupTuple()

    report_ch = Channel.of([
        "${params.projectName}",
        "${params.genome}", 
        "${params.assembly}", 
        "${params.shortSpecies}", 
        "${params.design}",
        "${params.colorFactors}",
        "${params.pValCutoff}",
        "${params.genesToShow}",
        "${params.DeOutDir}",
        "${params.countsDir}",
        "${params.templateDir}",
        "${params.reportFile}"] 
        )
        .combine( Channel.fromPath("${params.sampleSheet}") )
        .combine( Channel.fromPath("${params.contrastFile}") )
        .combine( Channel.fromPath("${params.tx2gene}") )
        .combine( Channel.fromPath("${params.gtfFile}") )
        .combine( Channel.fromPath("${params.quantOutDir}") )
        .combine( Channel.fromPath("${params.rScript}") )
        .combine( Channel.fromPath("${params.rmdFile}") )

    // add index path to csv channel
    // run salmon process and collect all outputs
    salmon_out_ch = SALMON( csv_channel.combine( Channel.fromPath("${params.salmonIndex}")) ) |
     collect

    // add salmon outputs to report channel
    // run RNAseq report process
    RNASEQREPORT(report_ch.combine(salmon_out_ch))
}

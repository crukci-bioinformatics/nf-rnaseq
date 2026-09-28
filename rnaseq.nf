#!/usr/bin/env nextflow

/*
 * Main rnaseq work flow.
 */

include { checkParameters; checkKickstartCSV; displayParameters; checkRNAseqSampleSheet; checkRNAseqContrastFile  } from "./components/configuration"
include { SALMON } from "./processes/salmon"
include { RNASEQREPORT } from "./processes/rnaseqreportprocess"

/*
 * Main work flow. For each sample in alignment.csv, start quantifying.
 * Finally generate a RNAseq report
 */

workflow
{
    main:

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

    if (params.quantTool == 'salmon')
    {
        if (!params.pairedEnd)
        {
            exit 1, "rnaseq pipeline currently supports paired-end data"
        }
    }
    else
    {
        exit 1, "rnaseq pipeline currently supports only salmon"
    }

    displayParameters(params)

    def csv_channel = channel
        .fromPath(params.kickstartCSV)
        .splitCsv(header: true, quote: '"', strip: true)
        .map { row -> tuple("${row.SampleName}", file("${params.fastqDir}/${row.Read1}", checkIfExists:true), file("${params.fastqDir}/${row.Read2}", checkIfExists:true)) }
        .groupTuple()

    def report_ch = channel.of([
        "${params.projectName}",
        "${params.species}",
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
        .combine( channel.fromPath("${params.sampleSheet}") )
        .combine( channel.fromPath("${params.contrastFile}") )
        .combine( channel.fromPath("${params.tx2gene}") )
        .combine( channel.fromPath("${params.gtfFile}") )
        .combine( channel.fromPath("${params.rScript}") )
        .combine( channel.fromPath("${params.rmdFile}") )

    // add index path to csv channel
    // run salmon process and collect all outputs
    def salmon_out = SALMON( csv_channel.combine( channel.fromPath("${params.salmonIndex}")) )
    // wrapped in a list so combine() below keeps all per-sample results as one input,
    // instead of flattening them into separate positional tuple elements
    def salmon_out_ch = salmon_out.collect().map { results -> [results] }

    // add salmon outputs to report channel
    // run RNAseq report process
    RNASEQREPORT(report_ch.combine(salmon_out_ch))

    publish:
    quant    = salmon_out
    counts   = RNASEQREPORT.out.counts
    de       = RNASEQREPORT.out.de
    template = RNASEQREPORT.out.template
    report   = RNASEQREPORT.out.report
}

output {
    quant    { path params.quantOutDir }
    counts   { path '.' }
    de       { path '.' }
    template { path '.' }
    report   { path '.' }
}

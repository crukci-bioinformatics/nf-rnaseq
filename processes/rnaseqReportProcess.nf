/*
* process for running RNAseq report
*/


process RNASEQREPORT 
{
    publishDir "${params.countsDir}", mode:"copy"
    publishDir "${params.DeOutDir}", mode:"copy"
    publishDir "${params.templateDir}", mode:"copy"
    publishDir "${params.reportFile}", mode:"copy"

    cpus 4
    memory { 8.GB * task.attempt }
    time 3.hour
    maxRetries 2
    
    input:
        tuple val(sample_name),  file(r1_fqs), file(r2_fqs)

        tuple val(projectName), \
        path(sampleSheet), \
        val(genome), \
        val(assembly), \
        path(quantOutDir), \
        path(tx2gene), \
        path(gtfFile), \
        path(contrastFile), \
        val(design), \
        path(countsDir), \
        val(colorFactors), \
        path(DeOutDir), \
        val(pValCutoff), \
        val(genesToShow), \
        path(templateDir), \
        path(reportFile)

    output:
        path "DE"

    shell:
        template "rnaseq/rnaseq.sh"

}
/*
* process for running salmon
*/
import nextflow.util.BlankSeparatedList
/*
* Quantification with salmon (pair-end reads)
* TODO: Quantification with single-end reads to be implimented
*/

process SALMON 
{
    label 'salmon'
    publishDir "${params.quantOutDir}", mode:"copy"
    
    cpus 4
    memory { 8.GB * task.attempt }
    time 3.hour
    maxRetries 2
    
    input:
        tuple val(sample_name),  file(r1_fqs), file(r2_fqs), path(index)
    
    output:
        path "${sample_name}"

    shell:
        template "salmon/salmonpe.sh"

}
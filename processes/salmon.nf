/*
* process for running salmon
*/
/*
* Quantification with salmon (pair-end reads)
* TODO: Quantification with single-end reads to be implimented
*/

process SALMON 
{
    //label 'salmon'
    cpus 4
    memory { 8.GB * task.attempt }
    time 3.h
    maxRetries 2

    input:
        tuple val(sample_name),  file(r1_fqs), file(r2_fqs), path(index)
    
    output:
        path "${sample_name}"

    script:
        template "salmon/salmonpe.sh"

    stub:
        """
        mkdir -p ${sample_name}
        touch ${sample_name}/quant.sf
        """
}
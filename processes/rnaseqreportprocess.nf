/*
* process for running RNAseq report
*/
/*
* TODO: Currently, this process copies everything to the work directory (stageInMode 'copy')
* A report is then generated
* Efficient way is through soft links, but I am unable to find a solution
*/


process RNASEQREPORT {

    //label 'report'

    cpus 4
    memory { 8.GB * task.attempt }
    time 3.h
    maxRetries 2

    stageInMode 'copy'

    input:
        tuple val(projectName),
            val(species),
            val(assembly),
            val(shortSpecies),
            val(design),
            val(colorFactors),
            val(pValCutoff),
            val(genesToShow),
            val(DeOutDir),
            val(countsDir),
            val(templateDir),
            val(reportFile),
            file(sampleSheet),
            file(contrastFile),
            file(tx2gene),
            file(gtfFile),
            file(rScript),
            file(rmdFile),
            path(quantResults, stageAs: 'quantOut/*')
    output:
        path "${countsDir}", emit: counts
        path "${DeOutDir}", emit: de
        path "${templateDir}", emit: template
        path "${reportFile}", emit: report

    script:
    """
        Rscript "${rScript}" \
        --project="${projectName}" \
        --species="${species}" \
        --assembly="${assembly}" \
        --design="${design}" \
        --factorName="${colorFactors}" \
        --pValCutoff="${pValCutoff}" \
        --genesToShow="${genesToShow}" \
        --samplesheet="${sampleSheet}" \
        --quantOut="quantOut" \
        --tx2geneFile="${tx2gene}" \
        --gtfFile="${gtfFile}" \
        --contrastFile="${contrastFile}" \
        --countsDir="${countsDir}" \
        --DeOutDir="${DeOutDir}" \
        --templateDir="${templateDir}" \
        --reportFile="${reportFile}"
    """

    stub:
    """
    mkdir -p "${countsDir}" "${DeOutDir}" "${templateDir}"
    touch "${reportFile}"
    """
}
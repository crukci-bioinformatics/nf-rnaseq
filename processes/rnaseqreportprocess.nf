/*
* process for running RNAseq report
*/
import nextflow.util.BlankSeparatedList
/*
* TODO: Currently, this process copies everything to the work directory (stageInMode 'copy')
* A report is then generated
* Efficient way is through soft links, but I am unable to find a solution
*/


process RNASEQREPORT () {

    //label 'report'

    cpus 4
    memory { 8.GB * task.attempt }
    time 3.hour
    maxRetries 2

    stageInMode 'copy'
    //publishDir "${projectDir}", mode:"copy"
    //publishDir "${workDir}", mode:"copy"
    publishDir "${launchDir}", mode:"copy"

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
            file(quantOutDir),
            file(rScript),
            file(rmdFile)
    output:
        path "${countsDir}"
        path "${DeOutDir}" 
        path "${templateDir}"
        path "${reportFile}"

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
        --quantOut="${quantOutDir}" \
        --tx2geneFile="${tx2gene}" \
        --gtfFile="${gtfFile}" \
        --contrastFile="${contrastFile}" \
        --countsDir="${countsDir}" \
        --DeOutDir="${DeOutDir}" \
        --templateDir="${templateDir}" \
        --reportFile="${reportFile}"
    """ 
}
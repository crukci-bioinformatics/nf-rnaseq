/*
 * Functions used in checking the configuration of the pipeline before it starts.
 */

include { logException } from './debugging'

/*
 * Check the parameters from rnaseq.config and the command line are
 * set and valid.
 */
def checkParameters(params)
{
    def errors = false
    def referenceRootWarned = false
    def referenceRootWarning = 'Reference data root directory not set. Use --referenceRoot with path to the top of the reference structure.'

    // Basic settings

    if (!params.containsKey('quantTool'))
    {
        log.error "quantificatio tool not specified. Use --quantTool with 'salmon'."
        errors = true
    }
    if (!params.containsKey('endType'))
    {
        log.error "Sequencing method not set. Use --endType with 'se' (single read) or 'pe' (paired end)."
        errors = true
    }
    if (!params.containsKey('species'))
    {
        log.error 'Species folder not set. Use --species and give the species name with underscores in place of spaces, eg. "homo_sapiens".'
        errors = true
    }
    if (!params.containsKey('shortSpecies'))
    {
        log.error 'Species abbreviation not set. Use --shortSpecies  to set it, eg. "hsa", "mmu".'
        errors = true
    }
    if (!params.containsKey('assembly'))
    {
        log.error 'Genome assembly not set. Use --assembly  to set it, eg. "GRCh38".'
        errors = true
    }
    if (!params.containsKey('salmonVersion'))
    {
        log.error 'salman version not set. Use --salmonVersion  to set it, eg. "1.8.0".'
        errors = true
    }
    if (!params.containsKey('fastqDir'))
    {
        log.error 'fastq folder not set. Use --fastqDir  to set it, eg. "fastq".'
        errors = true
    }
    if (!params.containsKey('quantOutDir'))
    {
        log.error 'quantification output folder is not set. use --quantOutDir  to set it, eg. "salmonOut"'
        errors = true
    }
    if (!params.containsKey('kmerLen'))
    {
        log.error 'salmon kmer length not set. use --kmerLen  to set it, eg. "31"'
        errors = true
    }
    if (!params.containsKey('sampleSheet'))
    {
        log.error 'RNAseq sample sheet not set. use --sampleSheet  to set it. eg. "samplesheet.csv"'
        errors = true
    }

    if (!params.containsKey('projectName'))
    {
        log.error 'RNAseq project name not set. use --projectName  to set it, eg. "test_project"'
        errors = true
    }

    if (!params.containsKey('contrastFile'))
    {
        log.error 'RNAseq contrast file not set. use --contrastFile  to set it, eg. "contrast.csv"'
        errors = true
    }

    if (!params.containsKey('design'))
    {
        log.error 'RNAseq design not set. use --design to set it, eg. "SampleGroup+Treatment"'
        errors = true
    }

    if (!params.containsKey('countsDir'))
    {
        log.error 'RNAseq counts directory not set. use --countsDir to set it, eg. "counts"'
        errors = true
    }

    if (!params.containsKey('colorFactors'))
    {
        log.error 'RNAseq color factors (column names of metadata sheet) not set. use --colorFactors to set it, eg. "SampleGroup,batch"'
        errors = true
    }

    if (!params.containsKey('DeOutDir'))
    {
        log.error 'RNAseq DE output folder name not set. use --DeOutDir to set it, eg. "DE_analysis"'
        errors = true
    }

    if (!params.containsKey('pValCutoff'))
    {
        log.error 'RNAseq p-value cut-off not set. use --pValCutoff to set it, eg. "0.05"'
        errors = true
    }

    if (!params.containsKey('genesToShow'))
    {
        log.error 'RNAseq, gene names to show on plots not set. use --genesToShow to set it, eg. "ESR1"'
        errors = true
    }

    if (!params.containsKey('templateDir'))
    {
        log.error 'RNAseq,report template directory not set. use --templateDir to set it, eg. "report_dir"'
        errors = true
    }

    if (!params.containsKey('reportFile'))
    {
        log.error 'RNAseq,report file name not set. use --reportFile to set it, eg. "RNAseqReport.html"'
        errors = true
    }

    if (errors)
    {
        log.warn "Missing arguments can also be added to rnaseq.config instead of being supplied on the command line."
        return false
    }

    params.quantTool = params.quantTool.toLowerCase()
    params.assemblyPrefix = "${params.shortSpecies}.${params.assembly}"

    // Decipher single read or paired end
    // Currently only supports pair end reads

    def endTypeChar = params.endType.toLowerCase()[0]
    if (endTypeChar == 's')
    {
        params.pairedEnd = false
    }
    else if (endTypeChar == 'p')
    {
        params.pairedEnd = true
    }
    else
    {
        log.error "End type must be given to indicate single read (se/sr) or paired end (pe)."
        errors = true
    }

    if (params.quantTool == 'salmon')
    {
        if (!params.containsKey('salmonIndex'))
        {
            if (!params.containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
            else
            {
                params.salmonIndex = "${params.referenceRoot}/${params.species}/${params.assembly}/salmon-${params.salmonVersion}/k${params.kmerLen}"
                params.tx2gene = "${params.referenceRoot}/${params.species}/${params.assembly}/salmon-${params.salmonVersion}/tx2gene.tsv"
                params.gtfFile = "${params.referenceRoot}/${params.species}/${params.assembly}/annotation/${params.shortSpecies}.${params.assembly}.gtf"
            }
        }
    }
    else
    {
        log.error "quantification tool must be 'salmon'."
        errors = true
    }

    // Check if reference files and directories are set. If not, default to our
    // standard structure.

    return !errors
}

/*
 * Write a log message summarising how the pipeline is configured and the
 * locations of reference files that will be used.
 */

def displayParameters(params)
{
    log.info "${params.pairedEnd ? 'Paired end' : 'Single read'} quantification against ${params.species} ${params.assembly} using ${params.quantTool.toUpperCase()}."

    if (params.quantTool == 'salmon')
    {
        log.info "salmon index: ${params.salmonIndex}"
        log.info "tx2gene file: ${params.tx2gene}"
        log.info "salmon version: ${params.salmonVersion}"
        log.info "salmon kmer length: ${params.kmerLen}"
    }
}

/*
 * Check the alignment CSV file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 */
def checkKickstartCSV(params)
{
    def ok = true
    try
    {
        def rows = file(params.kickstartCSV).splitCsv(header: true, quote: '"', strip: true)
        def headers = rows ? rows[0].keySet() : []

        if (!headers.contains('Read1'))
        {
            log.error "${params.kickstartCSV} must contain a column 'Read1'."
            ok = false
        }
        if (params.pairedEnd && !headers.contains('Read2'))
        {
            log.error "${params.kickstartCSV} must contain a column 'Read2' for paired end."
            ok = false
        }
        if (!headers.contains('SampleName'))
        {
            log.error "${params.kickstartCSV} must contain a column 'SampleName'."
            ok = false
        }

        if (ok)
        {
            rows.eachWithIndex
            { record, idx ->
                def rowNum = idx + 2
                if (!record.Read1)
                {
                    log.error "In ${params.kickstartCSV} file; No 'Read1' file name set on line ${rowNum}."
                    ok = false
                }
                if (params.pairedEnd && !record.Read2)
                {
                    log.error "In ${params.kickstartCSV} file; No 'Read2' file name set on line ${rowNum}."
                    ok = false
                }

                if (!record.SampleName)
                {
                    log.error "In ${params.kickstartCSV} file; No 'SampleName' defined on line ${rowNum}."
                    ok = false
                }
                else
                {
                    def s = record.SampleName
                    if (Character.isDigit(s.charAt(0)))
                    {
                        log.error "In ${params.kickstartCSV} file; Sample name '${s}', can not start with a number on line ${rowNum}."
                        ok = false
                    }
                    if (!s.matches("[a-zA-Z0-9._]*"))
                    {
                        log.error "In ${params.kickstartCSV} file; Sample name '${s}'', can not contain white space and/or special character line ${rowNum}. Only 'a-z,A-Z,0-9, .,and _' are allowed"
                        ok = false
                    }
                }
            }
        }
    }
    catch (Exception e)
    {
        logException(e)
        ok = false
    }

    return ok
}




/*
 * Check the RNAseq sample sheet file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 */
def checkRNAseqSampleSheet(params)
{
    def ok = true
    try
    {
        def rows = file(params.sampleSheet).splitCsv(header: true, quote: '"', strip: true)
        def headers = rows ? rows[0].keySet() : []

        if (!headers.contains('SampleName'))
        {
            log.error "${params.sampleSheet} must contain a column 'SampleName'."
            ok = false
        }

        if (!headers.contains('SampleGroup'))
        {
            log.error "${params.sampleSheet} must contain a column 'SampleGroup'."
            ok = false
        }

        if (ok)
        {
            rows.eachWithIndex
            { record, idx ->
                def rowNum = idx + 2
                if (!record.SampleName)
                {
                    log.error "In ${params.sampleSheet} file,  No 'SampleName'  name set on line ${rowNum}."
                    ok = false
                }
                else
                {
                    def s = record.SampleName
                    if (Character.isDigit(s.charAt(0)))
                    {
                        log.error "In ${params.sampleSheet} file, Sample name ${s}, can not start with a number on line ${rowNum}."
                        ok = false
                    }
                    if (!s.matches("[a-zA-Z0-9._]*"))
                    {
                        log.error "In ${params.sampleSheet} file, Sample name ${s}, can not contain white space and/or special character line ${rowNum}. Only 'a-z,A-Z,0-9, .,and _' are allowed"
                        ok = false
                    }
                }

                if (!record.SampleGroup)
                {
                    log.error "No 'SampleGroup' defined on line ${rowNum}."
                    ok = false
                }
                else
                {
                    def s = record.SampleGroup
                    if (Character.isDigit(s.charAt(0)))
                    {
                        log.error "In ${params.sampleSheet} file, Sample group '${s}'', can not start with a number on line ${rowNum}."
                        ok = false
                    }
                    if (!s.matches("[a-zA-Z0-9._]*"))
                    {
                        log.error "In ${params.sampleSheet} file, Sample group '${s}', can not contain white space and/or special character line ${rowNum}. Only 'a-z,A-Z,0-9, .,and _' are allowed"
                        ok = false
                    }
                }
            }
        }
    }
    catch (Exception e)
    {
        logException(e)
        ok = false
    }

    return ok
}


/* contrast file sanity check
*/
def checkRNAseqContrastFile(params)
{
    def ok = true
    try
    {
        def rows = file(params.contrastFile).splitCsv(header: true, quote: '"', strip: true)
        def headers = rows ? rows[0].keySet() : []

        if (!headers.contains('numerator'))
        {
            log.error "${params.contrastFile} must contain a column 'numerator'."
            ok = false
        }

        if (!headers.contains('denominator'))
        {
            log.error "${params.contrastFile} must contain a column 'denominator'."
            ok = false
        }

        if (ok)
        {
            rows.eachWithIndex
            { record, idx ->
                def rowNum = idx + 2
                if (!record.numerator)
                {
                    log.error "In ${params.contrastFile} file,  No 'numerator'  name set on line ${rowNum}."
                    ok = false
                }

                if (!record.denominator)
                {
                    log.error "In ${params.contrastFile} file,  No 'denominator'  name set on line ${rowNum}."
                    ok = false
                }
            }
        }
    }
    catch (Exception e)
    {
        logException(e)
        ok = false
    }

    return ok
}

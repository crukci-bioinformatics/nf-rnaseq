/*
 * Functions used in checking the configuration of the pipeline before it starts.
 */

@Grab('org.apache.commons:commons-csv:1.8')
import java.nio.file.Files
import org.apache.commons.csv.*

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

    params.with
    {
        // Basic settings

        if (!containsKey('quantTool'))
        {
            log.error "quantificatio tool not specified. Use --quantTool with 'salmon'."
            errors = true
        }


        if (!containsKey('endType'))
        {
            log.error "Sequencing method not set. Use --endType with 'se' (single read) or 'pe' (paired end)."
            errors = true
        }
        if (!containsKey('species'))
        {
            log.error 'Species folder not set. Use --species and give the species name with underscores in place of spaces, eg. "homo_sapiens".'
            errors = true
        }
        if (!containsKey('shortSpecies'))
        {
            log.error 'Species abbreviation not set. Use --shortSpecies  to set it, eg. "hsa", "mmu".'
            errors = true
        }
        if (!containsKey('assembly'))
        {
            log.error 'Genome assembly not set. Use --assembly  to set it, eg. "GRCh38".'
            errors = true
        }
        if (!containsKey('salmonVersion'))
        {
            log.error 'salman version not set. Use --salmonVersion  to set it, eg. "1.8.0".'
            errors = true
            
        }
        if (!containsKey('fastqDir'))
        {
            log.error 'fastq folder not set. Use --fastqDir  to set it, eg. "fastq".'
            errors = true
        }
        if (!containsKey('quantOutDir'))
        {
            log.error 'quantification output folder is not set. use --quantOutDir  to set it, eg. "salmonOut"'
        }
        if (!containsKey('kmerLen'))
        {
            log.error 'salmon kmer length not set. use --kmerLen  to set it, eg. "31"'
        }
        if (!containsKey('sampleSheet'))
        {
            log.error 'RNAseq sample sheet not set. use --sampleSheet  to set it. eg. "samplesheet.csv"'
        }

        if (!containsKey('projectName'))
        {
            log.error 'RNAseq project name not set. use --projectName  to set it, eg. "test_project"'
        }

        if (!containsKey('contrastFile'))
        {
            log.error 'RNAseq contrast file not set. use --contrastFile  to set it, eg. "contrast.csv"'
        }

        if (!containsKey('design'))
        {
            log.error 'RNAseq design not set. use --design to set it, eg. "SampleGroup+Treatment"'
        }

        if (!containsKey('countsDir'))
        {
            log.error 'RNAseq counts directory not set. use --countsDir to set it, eg. "counts"'
        }

        if (!containsKey('colorFactors'))
        {
            log.error 'RNAseq color factors (column names of metadata sheet) not set. use --colorFactors to set it, eg. "SampleGroup,batch"'
        }

        if (!containsKey('DeOutDir'))
        {
            log.error 'RNAseq DE output folder name not set. use --DeOutDir to set it, eg. "DE_analysis"'
        }

        if (!containsKey('pValCutoff'))
        {
            log.error 'RNAseq p-value cut-off not set. use --pValCutoff to set it, eg. "0.05"'
        }

        if (!containsKey('genesToShow'))
        {
            log.error 'RNAseq, gene names to show on plots not set. use --genesToShow to set it, eg. "ESR1"'
        }

        if (!containsKey('templateDir'))
        {
            log.error 'RNAseq,report template directory not set. use --templateDir to set it, eg. "report_dir"'
        }

        if (!containsKey('reportFile'))
        {
            log.error 'RNAseq,report file name not set. use --reportFile to set it, eg. "RNAseqReport.html"'
        }

        if (errors)
        {
            log.warn "Missing arguments can also be added to rnaseq.config instead of being supplied on the command line."
            return false
        }

        quantTool = quantTool.toLowerCase()
        assemblyPrefix = "${shortSpecies}.${assembly}"

        // Decipher single read or paired end 
        // Currently only supports pair end reads
        

        switch (endType.toLowerCase()[0])
        {
            case 's':
                pairedEnd = false
                break

            case 'p':
                pairedEnd = true
                break

            default:
                log.error "End type must be given to indicate single read (se/sr) or paired end (pe)."
                errors = true
                break
        }

        switch (quantTool)
        {
            case 'salmon':
                if (!containsKey('salmonIndex'))
                {
                    if (!containsKey('referenceRoot'))
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
                        salmonIndex = "${referenceRoot}/${species}/${assembly}/salmon-${salmonVersion}/k${kmerLen}"
                        tx2gene = "${referenceRoot}/${species}/${assembly}/salmon-${salmonVersion}/tx2gene.tsv"
                        gtfFile = "${referenceRoot}/${species}/${assembly}/annotation/${shortSpecies}.${assembly}.gtf"
                    }
                }
                break

            default:
                log.error "quantification tool must be 'salmon'."
                errors = true
                break
        }

        // Check if reference files and directories are set. If not, default to our
        // standard structure.

        if (errors)
        {
            return false
        } 
    } 
    return !errors
}

/*
 * Write a log message summarising how the pipeline is configured and the
 * locations of reference files that will be used.
 */

def displayParameters(params)
{
    params.with
    {
        log.info "${pairedEnd ? 'Paired end' : 'Single read'} quantification against ${species} ${assembly} using ${quantTool.toUpperCase()}."
        
        switch (quantTool)
        {
            case 'salmon':
                log.info "salmon index: ${salmonIndex}"
                log.info "tx2gene file: ${tx2gene}"
                log.info "salmon version: ${salmonVersion}"
                log.info "salmon kmer length: ${kmerLen}"
                break
        }
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
        def driverFile = file(params.kickstartCSV)
        driverFile.withReader('UTF-8')
        {
            stream ->
            def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
            def first = true

            for (record in parser)
            {
                if (first)
                {
                    if (!record.isMapped('Read1'))
                    {
                        log.error "${params.kickstartCSV} must contain a column 'Read1'."
                        ok = false
                    }
                    if (params.pairedEnd && !record.isMapped('Read2'))
                    {
                        log.error "${params.kickstartCSV} must contain a column 'Read2' for paired end."
                        ok = false
                    }
                    if (!record.isMapped('SampleName'))
                    {
                        log.error "${params.kickstartCSV} must contain a column 'SampleName'."
                        ok = false
                    }
                    first = false
                    if (!ok)
                    {
                        break
                    }
                }

                def rowNum = parser.recordNumber + 1
                if (!record.get('Read1'))
                {
                    log.error "In ${params.kickstartCSV} file; No 'Read1' file name set on line ${rowNum}."
                    ok = false
                }
                if (params.pairedEnd && !record.get('Read2'))
                {
                    log.error "In ${params.kickstartCSV} file; No 'Read2' file name set on line ${rowNum}."
                    ok = false
                }

                if (!record.get('SampleName'))
                {
                    log.error "In ${params.kickstartCSV} file; No 'SampleName' defined on line ${rowNum}."
                    ok = false
                } else {
                    s = record.get('SampleName')
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
        def driverFile = file(params.sampleSheet)
        driverFile.withReader('UTF-8')
        {
            stream ->
            def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
            def first = true

            for (record in parser)
            {
                if (first)
                {
                    if (!record.isMapped('SampleName'))
                    {
                        log.error "${params.sampleSheet} must contain a column 'SampleName'."
                        ok = false
                    }

                    if (!record.isMapped('SampleGroup'))
                    {
                        log.error "${params.sampleSheet} must contain a column 'SampleGroup'."
                        ok = false
                    }

                    first = false
                    if (!ok)
                    {
                        break
                    }
                }

                def rowNum = parser.recordNumber + 1
                if (!record.get('SampleName'))
                {
                    log.error "In ${params.sampleSheet} file,  No 'SampleName'  name set on line ${rowNum}."
                    ok = false
                } else {
                    s = record.get('SampleName')
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
                
                
                if (!record.get('SampleGroup'))
                {
                    log.error "No 'SampleGroup' defined on line ${rowNum}."
                    ok = false
                } else {

                    s = record.get('SampleGroup')
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
        def driverFile = file(params.contrastFile)
        driverFile.withReader('UTF-8')
        {
            stream ->
            def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
            def first = true

            for (record in parser)
            {
                if (first)
                {
                    if (!record.isMapped('numerator'))
                    {
                        log.error "${params.contrastFile} must contain a column 'numerator'."
                        ok = false
                    }

                    if (!record.isMapped('denominator'))
                    {
                        log.error "${params.contrastFile} must contain a column 'denominator'."
                        ok = false
                    }

                    first = false
                    if (!ok)
                    {
                        break
                    }
                }

                def rowNum = parser.recordNumber + 1
                if (!record.get('numerator'))
                {
                    log.error "In ${params.contrastFile} file,  No 'numerator'  name set on line ${rowNum}."
                    ok = false
                } 
                
                if (!record.get('denominator'))
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



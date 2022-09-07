suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(assertthat))
suppressPackageStartupMessages(library(rmarkdown))
##################### START OF FUNCTIONS #######################################
# parse command line options
mkOptParser <- function() {
  options <- list(
    make_option(
      "--project", type="character", metavar="projectName",
      help="The name of the project."),
    make_option("--samplesheet", type="character", metavar="samplesheet",
                help="Sample sheet file"),
    make_option( "--genome", type="character", metavar="genome",
                 help="The name of the species."),
    make_option("--assembly", type="character", metavar="assembly",
                help="Geneome assembly"),
    make_option("--quantOut", type='character', metavar="quantOut",
                help="RNAseq quantification output folder"),
    make_option("--tx2geneFile", type="character", metavar="tx2geneFile",
                help="Transcript to gene ID mapping file"),
    make_option("--gtfFile", type="character", metavar="gtfFile",
                help="GTF file name"),
    make_option("--contrastFile", type="character", metavar="contrastFile",
                help="Contrast file neme"),
    make_option("--design", type="character", metavar="design",
                help="Deseq2 design"),
    make_option("--countsDir", type="character", metavar="countsDir",
                help="Folder name to save the counts output files"),
    make_option("--factorName", type="character", metavar="factorName",
                help="Factor name to color the PCA plot"),
    make_option("--DeOutDir", type = "character", metavar="DeOutDir",
                help="DE analysis output folder"),
    make_option("--pValCutoff", type="numeric", metavar="pValCutoff",
                help = "p-value cut-off"),
    make_option("--genesToShow", type="character", metavar="genesToShow",
                help="Gene names to shows on MA and volcano plots"),
    make_option("--templateDir", type="character", metavar="templateDir",
                help="Report template ditectory"),
    make_option("--reportFile", type="character", metavar="reportFile",
                help="RNAseq report file name")

  )

  parser <- OptionParser(option_list=options)
  return(parser)
}

writeVariablesForRmd <- function(varList, outFile){
  vars <- unlist(varList)
  varNames <- names(vars)
  vars <- str_c("'", vars, "'", sep='')
  vars <- str_c(varNames, vars, sep=' <- ')
  vars <- tibble(variableNames = vars)
  write_tsv(x = vars, file = outFile)
}

getUserPlayableRmd <- function(rawRmd, varFile, titleName) {
  userRmdFile <- str_c(dirname(rawRmd),
                       str_c('userPlayable', basename(rawRmd), sep='_'),
                       sep='/')
  rmdLines <- read_lines(rawRmd)
  varLines <- read_lines(varFile, skip=1)

  rmdLines[2] <- str_c('title:',
                       str_c("'",titleName, "'", sep=''),
                       sep=' ')
  matchLine <- str_which(rmdLines, pattern = '```\\{r variable_substitute\\}' )

  allLines <- c(rmdLines[1:matchLine], varLines, rmdLines[(matchLine+1):length(rmdLines)])

  write_lines(x=allLines, file = userRmdFile)
}


rnaSeqReport <- function(opts){

  genome = opts$genome

  varList <- list(
    projectName = opts$project,
    samplesheet = opts$samplesheet,
    genome = opts$genome,
    assembly = opts$assembly,
    quantOut = opts$quantOut,
    tx2geneFile = opts$tx2geneFile,
    gtfFile = opts$gtfFile,
    contrastFile = opts$contrastFile,
    design = opts$design,
    countsDir = opts$countsDir,
    factorName = opts$factorName,
    DeOutDir = opts$DeOutDir,
    pValCutoff = opts$pValCutoff,
    genesToShow = opts$genesToShow,
    templateDir = opts$templateDir,
    reportFile = opts$reportFile
  )

  projectName = opts$project
  samplesheet = opts$samplesheet
  genome = opts$genome
  assembly = opts$assembly
  quantOut = opts$quantOut
  tx2geneFile = opts$tx2geneFile
  gtfFile = opts$gtfFile
  contrastFile = opts$contrastFile
  design = opts$design
  countsDir = opts$countsDir
  factorName = opts$factorName
  DeOutDir = opts$DeOutDir
  pValCutoff = opts$pValCutoff
  genesToShow = opts$genesToShow
  templateDir = opts$templateDir
  reportFile = opts$reportFile

  reportTemplate = system.file("extdata/rnaseqReport.Rmd",package = "rnaseqRcode")
  assert_that(reportTemplate != "",msg = "reportTemplate missing")

  reportWritableTemplate <- file.path(templateDir,basename(reportTemplate))
  file.copy(reportTemplate,reportWritableTemplate, overwrite = TRUE)

  tempDir <- tempdir()
  render(reportWritableTemplate,
         output_file = reportFile,
         intermediates_dir = tempDir,
         knit_root_dir = tempDir,
         output_dir = dirname(reportFile),
         quiet = FALSE)

  varFile <- str_c(templateDir, 'variables.txt', sep='/')

  writeVariablesForRmd(varList = varList, outFile=varFile )

  getUserPlayableRmd(rawRmd = reportWritableTemplate,
                     varFile = varFile,
                     titleName = projectName)
}
##################### END OF FUNCTIONS #######################################

# Rscript runRNAseqReport.R --samplesheet=/Users/chilam01/Desktop/rnaseqRcode/data/samplesheet_corrected.csv --project=test_project --genome=Mus_musculus --assembly=GRCm38 --quantOut=/Users/chilam01/Desktop/rnaseqRcode/data/quantOut --tx2geneFile=/Users/chilam01/Desktop/rnaseqRcode/data/references/tx2gene.tsv --gtfFile="/Users/chilam01/Desktop/rnaseqRcode/data/references/mmu.GRCm38.gtf" --contrastFile="/Users/chilam01/Desktop/rnaseqRcode/data/contrasts.csv" --design=SampleGroup --countsDir="/Users/chilam01/Desktop/rnaseqRcode/data/counts" --factorName=SampleGroup --DeOutDir=/Users/chilam01/Desktop/rnaseqRcode/data/DEAnalysis/test1  --pValCutoff=0.05 --genesToShow=ESR1 --templateDir=/Users/chilam01/Desktop/rnaseqRcode/temp --reportFile=/Users/chilam01/Desktop/rnaseqRcode/temp/xxx.html
options(stringsAsFactors=FALSE)
# get arguments
parser <- mkOptParser()

# parse arguments
cmdLine <- parse_args(parser, args=commandArgs(trailingOnly=TRUE),
                      positional_arguments=TRUE)

opts <- cmdLine$options

# create required directories

if(!dir.exists(opts$countsDir)){
  dir.create(opts$countsDir)
}

if(!dir.exists(opts$DeOutDir)){
  dir.create(opts$DeOutDir)
}

if(!dir.exists(opts$templateDir)){
  dir.create(opts$templateDir)
}




rnaSeqReport(opts)

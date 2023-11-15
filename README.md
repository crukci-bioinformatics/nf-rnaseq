##  CRUK-CI Bioinformatics RNAseq pipeline - Nexflow based
This is new RNAseq pipeline using Nexiflow rather than in house work flow manager.
### What does it do?
Transcript level quantification is performed using salmon on raw fastq files. Next, it generates various quality control metrics, followed by DESeq2 differential expression and generates a HTML report that contains all plots.

### How to run this pipeline?

Nextflow must be installed on your system in order to use the pipeline. Here are the instructions [found on the Nextflow web site](https://www.nextflow.io/docs/latest/getstarted.html#installation).
In the following sections, we assume that the downloaded `nextflow` script is on the path.

FASTQ files can be gathered using tools within CRUK-CI. The
[kick start application](https://internal-bioinformatics.cruk.cam.ac.uk/docs/nf-kickstart).
This pipeline will extract FASTQ files from the sequencing archive and create a CSV file that contains information about the files in the project directory (`alignment.csv`). 

The RNAseq pipeline configuration is required after the data has been assembled.
In the project directory, create a file called `rnaseq.config`. As this configuration is data-specific, it cannot be defined in the main pipeline. The file should contain:

```
params {
    projectName   =    <project name>               # E.g. "20220630_PearsallI_HG_RNAseq"
    species       =    <species folder name>        # E.g. "mus_musculus"
    shortSpecies  =    <species abbreviation>       # E.g. "mmu"
    assembly      =    <assembly name>              # E.g. "GRCm38"
    kickstartCSV  =    <CSV file from kickstart>    # E.g. "alignment.csv"
    sampleSheet   =    <RNAseq specific CSV file>   # E.g. "samplesheet.csv"
    contrastFile  =    <contrast CSV file>          # E.g. contrasts.csv
}
```
For the pipeline to run, this is the minimal information it needs.

After the FASTQ data was gathered, alignment.csv was generated and rnaseq.config was created, pipeline is ready to run.


```
nextflow run crukci-bioinformatics/nf-rnaseq -config rnaseq.config
```
It's that simple. By using fastq files and salmon tool, this pipeline quantifies transcript levels. Eventually generates a HTML report. 

### Controlling the Pipeline 

By choosing an appropriate profile and setting appropriate parameters, you can control the speed and output of the pipeline.

### Profiles

With no other option provided, the pipeline runs using the "standard" profile with 10 GB RAM, 6 cores. When no alternative is selected, this profile will be used.

There are two other profiles defined. "bioinf" is for our (Bioinformatics core)
_bioinf-srv008_ server, allowing the pipeline 20 cores and up to 80GB RAM. "cluster" is
for the CRUK-CI cluster, using Slurm to run parallel jobs across the cluster.

Add the `-profile` Nextflow command line option to choose the profile. Thus the command
line might become:

```
nextflow run crukci-bioinformatics/nf-rnaseq -config rnaseq.config -profile cluster
```

#### Additional Configuration

In addition to the minimum mandatory parameters, the user can also choose additional parameters. These can be added to `rnaseq.config`. Using genesToShow parameter, for example, user can supply genes to show on MA and volcano plots. Sample `rnaseq.config` file: sample_files/rnaseq.config

```
genesToShow  = "ESR1,GAPDH"
```

#### Command Line Switches

All of the parameters defined in `rnaseq.config` can be overridden on the command
line. Nextflow accepts double dash switches to set parameters using the same names as
provided in `rnaseq.config`. For example, to show genes of interest as a one off, one can run the pipeline like below.

```
nextflow run crukci-bioinformatics/nf-rnaseq -config rnaseq.config --genesToShow ="ESR1,GAPDH"
```

Command line switches override values defined in `rnaseq.config`.


#### Nextflow Further Configuration

[Nextflow configuration](https://www.nextflow.io/docs/latest/config.html).
[email notification](https://www.nextflow.io/docs/latest/config.html#scope-mail),
[tuning processes](https://www.nextflow.io/docs/latest/config.html#scope-process) or
[custom profiles](https://www.nextflow.io/docs/latest/config.html#config-profiles).

### Reference Data

The pipeline expects reference data to be set up in the structure defined by
[our reference data pipeline](https://internal-bioinformatics.cruk.cam.ac.uk/docs/referencegenomes/main.html).
The profiles have default paths for the root location of this structure for use on our
cluster and Bioinformatics core server. For the "standard" profile on one's local
machine, the reference root should be defined in `rnaseq.config`.

```
params {
    referenceRoot = '/home/reference_data'
}
```

### Singularity Cache

The rnaseq pipeline will fetch the container image it needs from DockerHub automatically.
It is placed in Nextflow's `work` directory by default for each project where you are using
the alignment pipeline. It is better to create a common directory elsewhere for Nextflow to
use so it doesn't fetch the (not small) image every time. This can be done by setting the
`NXF_SINGULARITY_CACHEDIR` environment variable on the command line, or more practically
in your `.bash_profile`.

```
export NXF_SINGULARITY_CACHEDIR=/data/my_nextflow_singularity_cache
```

### Content of `alignment.csv`

The `alignment.csv` file drives the salmon pipequantification part of pipeline. It lists FASTQ files. It must contain at lest three columns.

At CRUK-CI, we have the
[kick start application](https://internal-bioinformatics.cruk.cam.ac.uk/docs/nf-kickstart)
to help with this.

#### `alignment.csv` Columns

The order of the columns does not matter in this file, but the name of the columns
(the first row) is required. There may be additional columns in this file but these

##### "Read1", "Read2"

These columns are required. "Read1" is the name of the single or first read FASTQ files;
"Read2" is the name of the second read for paired end data. "Read2" can be left blank
for single read data (it will not be read).

##### "SampleName"

The "SampleName" column defines the sample name each FASTQ file belongs to. All FASTQ files
that have the same sample name are grouped togethet during salmon quantification step. Pipeline 
execution is aborted if sample names contain special characters, empty space, or start with a number. Make sure sample names are clear before running pipiline.

### Content of `samplesheet.csv`

The order of the columns does not matter in this file, but the name of the columns
(the first row) is required. There may be additional columns in this file but these
are the ones used by the pipeline. Sample `samplesheet.csv` file: sample_files/samplesheet.csv

##### "SampleName"

The "SampleName" column defines the sample name each salmon output folder belongs to. Pipeline 
execution is aborted if sample names contain special characters, empty space, or start with a number. Make sure sample names are clear before running pipiline.

##### "SampleGroup"

The "SampleGroup" column defines the group of samples that belongs to each SampleGroup in DESeq2 analysis. Pipeline execution is aborted if sample group contain special characters, empty space, or start with a number. Make sure sample names are clear before running pipiline.

### Content of `contrasts.csv`

A minimum of two columns are present in this file. Sample `contrast.csv` file: sample_files/contrasts.csv
##### "numerator"
In the DESeq2 analysis this is used as treatmnet group. Names must match those in SampleGroup column of samplesheet.csv file.

##### denominator

In the DESeq2 analysis this is used as control group. Names must match those in SampleGroup column of samplesheet.csv file.












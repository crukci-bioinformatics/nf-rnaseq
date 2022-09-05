sudo docker run -it rockylinux:8

INSTALL_DIR=/usr/local
BUILD_DIR=/tmp/rnaseq_software_build
TAROPTS="--no-same-owner --no-same-permissions"

dnf install -y dnf-plugins-core epel-release
dnf config-manager --set-enabled powertools
dnf makecache && dnf update -y


dnf install -y \
    bzip2 bzip2-devel diffutils gcc-c++ git  \
    libcurl-devel libxml2-devel make ncurses-devel openssl-devel \
    python3 python3-psycopg2 \
    R-core R-devel \
    unzip wget xz-devel zlib-devel \
    harfbuzz-devel libtiff-devel libjpeg-devel fribidi-devel

mkdir -p ${INSTALL_DIR} ${BUILD_DIR}


# install conda
CONDA_VERSION=py39_4.11.0
CONDA_MD5=4e2f31e0b2598634c80daa12e4981647
curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    echo "${CONDA_MD5}  miniconda3.sh" > miniconda3.md5 && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm -f miniconda3.sh miniconda3.md5


/opt/conda/bin/conda config --add channels conda-forge
/opt/conda/bin/conda config --add channels bioconda
/opt/conda/bin/conda install salmon=1.8.0


# Install R packages
/usr/bin/R --vanilla -e \
    "install.packages(pkgs = c('devtools', 'BiocManager', 'rmarkdown', 'optparse'), repos = c('https://cran.ma.imperial.ac.uk/', 'https://www.stats.bris.ac.uk/R/'))"

# Install required bioconductor packges for rnaseqRcode
/usr/bin/R --vanilla -e     \
    "BiocManager::install(c('DESeq2', 'tximport', 'rtracklayer', 'ComplexHeatmap', 'GenomeInfoDb'))"

/usr/bin/R --vanilla -e \
    "devtools::install_github('crukci-bioinformatics/rnaseqRcode', repos = c('https://cran.ma.imperial.ac.uk/'))"



########################################################################################################
# Docker image
# Date 02-09-2022
# build docker image
sudo docker build --tag crukcibioinformatics/rnaseq:0.2 .

# if /var is full you can remove unsued images by this command
docker image prune -a

# Push docker image file onto dockerhub
sudo docker push crukcibioinformatics/rnaseq:0.2

# test if everyting is working well
sudo docker run -it  crukcibioinformatics/rnaseq:0.2

##########################################################################################################

##########################################################################################################
# Date 02-09-2022
# Singulrity image
# build singularity image
# pwd: /data/personal/chilam01/play/salmon/container/rockylinux_01_09_2022/build_sing_image
singularity build --sandbox salmon_02_09_2022 docker://crukcibioinformatics/rnaseq:0.2
# Above created a salmon folder where you have all exicutables


# Create singularity image
singularity  pull sing_image.sif docker://crukcibioinformatics/rnaseq:0.2
# Above created sing_image.sif 
# Now I can use either working_image.sif or salmon folder for running 



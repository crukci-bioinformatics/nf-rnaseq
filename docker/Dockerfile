FROM    rockylinux:8

LABEL   maintainer="Chandra Chilamakuri<Chandra.Chilamakuri@cruk.cam.ac.uk>"

ENV SALMON_VERSION 1.9.0

ARG INSTALL_DIR=/usr/local
ARG BUILD_DIR=/tmp/rnaseq_software_build

ARG TAROPTS="--no-same-owner --no-same-permissions"

RUN dnf install -y dnf-plugins-core epel-release
RUN dnf config-manager --set-enabled powertools
RUN dnf makecache && dnf update -y

RUN dnf install -y \
    bzip2 bzip2-devel diffutils gcc-c++ git libgit2-devel \
    libcurl-devel libxml2-devel make ncurses-devel openssl-devel \
    python3 python3-psycopg2 \
    R-core R-devel \
    unzip wget xz-devel zlib-devel \
    harfbuzz-devel libtiff-devel libjpeg-devel fribidi-devel pandoc procps \
    cmake autoconf



RUN mkdir -p ${INSTALL_DIR} ${BUILD_DIR}


ARG CONDA_VERSION=py39_4.11.0
ARG CONDA_MD5=4e2f31e0b2598634c80daa12e4981647
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    echo "${CONDA_MD5}  miniconda3.sh" > miniconda3.md5 && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm -f miniconda3.sh miniconda3.md5


RUN curl -k -L https://github.com/COMBINE-lab/salmon/archive/v${SALMON_VERSION}.tar.gz -o salmon-v${SALMON_VERSION}.tar.gz && \
    tar xzf salmon-v${SALMON_VERSION}.tar.gz && \
    cd salmon-${SALMON_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. -DFETCH_BOOST=TRUE -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/salmon && make && make install

RUN /usr/bin/R --vanilla -e \
    "install.packages(pkgs = c('devtools', 'BiocManager', 'rmarkdown', 'optparse', 'tidyverse' ), repos = c('https://cran.ma.imperial.ac.uk/', 'https://www.stats.bris.ac.uk/R/'))"


RUN /usr/bin/R --vanilla -e     \
    "BiocManager::install(c('DESeq2', 'tximport', 'rtracklayer', 'ComplexHeatmap', 'GenomeInfoDb', 'ggbio'))"


RUN /usr/bin/R --vanilla -e \
    "devtools::install_github('crukci-bioinformatics/rnaseqRcode', repos = c('https://cran.ma.imperial.ac.uk/'))"


RUN /usr/bin/R --vanilla -e \
    "install.packages(pkgs = c('DT', 'ashr' ), repos = c('https://cran.ma.imperial.ac.uk/', 'https://www.stats.bris.ac.uk/R/'))"


ENV  PATH /opt/conda/bin:/usr/local/salmon/bin:$PATH
ENV LD_LIBRARY_PATH "/usr/local/salmon/lib"

RUN echo "export PATH=$PATH" > /etc/environment
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" > /etc/environment

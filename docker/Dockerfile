FROM debian:11.3-slim

LABEL   maintainer="Chandra Chilamakuri<Chandra.Chilamakuri@cruk.cam.ac.uk>" \
    version="0.1-test" \
    description="Nextflow RNAseq pipeline"


RUN apt-get update && \
    apt-get install -y git curl procps wget && \
    apt-get clean

ARG CONDA_VERSION=py39_4.11.0
ARG CONDA_MD5=4e2f31e0b2598634c80daa12e4981647


RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    echo "${CONDA_MD5}  miniconda3.sh" > miniconda3.md5 && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm miniconda3.sh miniconda3.md5

COPY conda.yml .
RUN /opt/conda/bin/conda env create -f conda.yml && /opt/conda/bin/conda clean -a

ENV  PATH /opt/conda/bin:/opt/conda/envs/RNAseq/bin:$PATH


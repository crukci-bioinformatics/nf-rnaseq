#version ?= latest
version ?= 0.2
build:
	docker build --tag crukcibioinformatics/rnaseq:${version} .

release: build
	docker push crukcibioinformatics/rnaseq:${version}
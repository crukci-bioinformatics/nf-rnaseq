#version ?= latest
version ?= 0.3
build:
	docker build --tag crukcibioinformatics/rnaseq:${version} .

release: build
	docker push crukcibioinformatics/rnaseq:${version}

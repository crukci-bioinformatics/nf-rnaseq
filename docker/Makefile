version ?= latest

build:
	docker build --tag crukcibioinformatics/rnaseq:${version} .

release: build
	docker push crukcibioinformatics/rnaseq:${version}
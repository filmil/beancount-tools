# Shortcut commands for beancount.

TOP_DIR := $(shell pwd)
OUTPUT_DIR := .output
UID := $(shell id -u)
GID := $(shell id -g)

FMTLOG_ERRFMT := "{{i}}{{.Text}}{{n}}"
FMTLOG_OUTFMT := "{{i}}{{.Text}}{{n}}"

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

REGISTRY := filipfilmar

VERSION := $(shell git describe --tags --always --dirty)

ifdef INTERACTIVE
		TTY:=--tty
else
		TTY:=
endif

DOCKER_COMMON := \
    -u "${UID}:${GID}" \
    --env="FMTLOG_ERRFMT=${FMTLOG_ERRFMT}" \
    --env="FMTLOG_OUTFMT=${FMTLOG_OUTFMT}"

DOCKER_BUILD := \
	docker run --rm --interactive ${TTY} \
    ${DOCKER_COMMON} \
		-v ${TOP_DIR}:/go/src/github.com/filmil/fintools \
		-v ${TOP_DIR}/.output/go/bin:/go/bin \
		-v ${TOP_DIR}/.output/go/pkg:/go/pkg \
		-v ${TOP_DIR}/.output/go/cache:/go/cache \
        beancount-build-tools:latest

.DEFAULT: build

.PHONY: build
build: buildenv build-tools

.PHONY: test
test: buildenv build-tools
	${RUN_NOPORT} nosetests -s -v --all-modules importers/

clean:
	rm -fr $(OUTPUT_DIR)

$(OUTPUT_DIR)/init:
	mkdir -p $(OUTPUT_DIR)
	touch $@

# Creates the golang work directory.
$(OUTPUT_DIR)/go:
	@echo "+++ Creating $@"
	@mkdir -p $@
	@mkdir -p $@/bin
	@mkdir -p $@/pkg
	@mkdir -p $@/cache

# Opens up a shell inside the $(OUTPUT_DIR)/buildenv container.
bash: buildenv
	${RUN_NOPORT} /bin/bash

DOCKER_BUILD_CMD := docker build --quiet

.PHONY: buildenv
buildenv: | $(OUTPUT_DIR)/buildenv
$(OUTPUT_DIR)/buildenv: $(OUTPUT_DIR)/init Dockerfile.buildenv
	${DOCKER_BUILD_CMD} -f Dockerfile.buildenv \
		 -t beancount-buildenv:latest . > $@

.PHONY: build-tools
build-tools: $(OUTPUT_DIR)/go | $(OUTPUT_DIR)/build-tools
$(OUTPUT_DIR)/build-tools: Dockerfile.build-tools
	${DOCKER_BUILD_CMD} -f Dockerfile.build-tools \
		-t beancount-build-tools:latest . > $@

.PHONY: release
release: push-buildenv push-build-tools

.PHONY: tag-buildenv
tag-buildenv: buildenv
	docker tag beancount-buildenv:latest \
			${REGISTRY}/beancount-buildenv:${VERSION}

.PHONY: push-buildenv
push-buildenv: tag-buildenv
	docker push ${REGISTRY}/beancount-buildenv:${VERSION}

.PHONY: tag-build-tools
tag-build-tools: build-tools
	docker tag beancount-build-tools:latest \
			${REGISTRY}/beancount-build-tools:${VERSION}

.PHONY: push-build-tools
push-build-tools: build-tools
	docker push ${REGISTRY}/beancount-build-tools:${VERSION}

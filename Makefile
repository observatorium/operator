SHELL=/usr/bin/env bash -o pipefail

GOBIN ?= $(shell pwd)/tmp/bin
BIN_DIR ?= $(GOBIN)

include .bingo/Variables.mk

VERSION := $(strip $(shell [ -d .git ] && git describe --always --tags --dirty))
BUILD_DATE := $(shell date -u +"%Y-%m-%d")
BUILD_TIMESTAMP := $(shell date -u +"%Y-%m-%dT%H:%M:%S%Z")
VCS_BRANCH := $(strip $(shell git rev-parse --abbrev-ref HEAD))
VCS_REF := $(strip $(shell [ -d .git ] && git rev-parse --short HEAD))
DOCKER_REPO ?= quay.io/observatorium/observatorium-operator

help: ## Displays help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# Generate manifests e.g. CRD, RBAC etc.
manifests: example/manifests/observatorium.yaml manifests/crds/core.observatorium.io_observatoria.yaml

manifests/crds/core.observatorium.io_observatoria.yaml: $(CONTROLLER_GEN) $(find api/v1alpha1 -type f -name '*.go')
	$(CONTROLLER_GEN) crd paths="./..." output:crd:artifacts:config=manifests/crds

example/manifests/observatorium.yaml: example/main.jsonnet
	$(JSONNET) -J jsonnet/vendor example/main.jsonnet | $(GOJSONTOYAML) > example/manifests/observatorium.yaml

fmt: ## Run go fmt against code
fmt:
	go fmt ./...

vet: ## Run go vet against code
vet:
	go vet ./...

generate: ## Generate code.
generate: api/v1alpha1/zz_generated.deepcopy.go

api/v1alpha1/zz_generated.deepcopy.go: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) object:headerFile=./hack/boilerplate.go.txt paths="./..."

container-build: ## Build the docker image
container-build:
	docker build --build-arg BUILD_DATE="$(BUILD_TIMESTAMP)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VCS_BRANCH="$(VCS_BRANCH)" \
		--build-arg DOCKERFILE_PATH="/Dockerfile" \
		-t $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION) .

container-push: ## Push the image
container-push: container-build
	docker tag $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION) $(DOCKER_REPO):latest
	docker push $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION)
	docker push $(DOCKER_REPO):latest

jsonnet-vendor: $(JB)
	cd jsonnet; $(JB) install

jsonnet-update: $(JB)
	cd jsonnet; $(JB) update

jsonnet-update-deployments: $(JB)
	cd jsonnet; $(JB) update github.com/observatorium/deployments

JSONNET_SRC = $(shell find . -type f -not -path './*vendor/*' \( -name '*.libsonnet' -o -name '*.jsonnet' \))
JSONNETFMT_CMD := $(JSONNETFMT) -n 2 --max-blank-lines 2 --string-style s --comment-style s

.PHONY: jsonnet-fmt
jsonnet-fmt: | $(JSONNETFMT)
	PATH=$$PATH:$(BIN_DIR):$(FIRST_GOPATH)/bin echo ${JSONNET_SRC} | xargs -n 1 -- $(JSONNETFMT_CMD) -i

# Tools
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

SHELL=/usr/bin/env bash -o pipefail

VERSION := $(strip $(shell [ -d .git ] && git describe --always --tags --dirty))
BUILD_DATE := $(shell date -u +"%Y-%m-%d")
BUILD_TIMESTAMP := $(shell date -u +"%Y-%m-%dT%H:%M:%S%Z")
VCS_BRANCH := $(strip $(shell git rev-parse --abbrev-ref HEAD))
VCS_REF := $(strip $(shell [ -d .git ] && git rev-parse --short HEAD))
DOCKER_REPO ?= quay.io/observatorium/observatorium-operator

BIN_DIR ?= $(shell pwd)/tmp/bin

CONTROLLER_GEN ?= $(BIN_DIR)/controller-gen
JB ?= $(BIN_DIR)/jb

# Generate manifests e.g. CRD, RBAC etc.
manifests: example/manifests/observatorium.yaml manifests/crds/core.observatorium.io_observatoria.yaml

manifests/crds/core.observatorium.io_observatoria.yaml: $(CONTROLLER_GEN) $(find api/v1alpha1 -type f -name '*.go')
	$(CONTROLLER_GEN) crd paths="./..." output:crd:artifacts:config=manifests/crds

example/manifests/observatorium.yaml: example/main.jsonnet
	jsonnet -J jsonnet/vendor example/main.jsonnet | gojsontoyaml > example/manifests/observatorium.yaml

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Generate code
generate: api/v1alpha1/zz_generated.deepcopy.go

api/v1alpha1/zz_generated.deepcopy.go: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) object:headerFile=./hack/boilerplate.go.txt paths="./..."

# Build the docker image
container-build:
	docker build --build-arg BUILD_DATE="$(BUILD_TIMESTAMP)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VCS_BRANCH="$(VCS_BRANCH)" \
		--build-arg DOCKERFILE_PATH="/Dockerfile" \
		-t $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION) .

# Push the image
container-push: container-build
	docker tag $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION) $(DOCKER_REPO):latest
	docker push $(DOCKER_REPO):$(VCS_BRANCH)-$(BUILD_DATE)-$(VERSION)
	docker push $(DOCKER_REPO):latest

vendor-jsonnet: $(JB)
	cd jsonnet; $(JB) install

jsonnet-update: $(JB)
	cd jsonnet; $(JB) update

jsonnet-update-deployments: $(JB)
	cd jsonnet; $(JB) update github.com/observatorium/deployments

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(CONTROLLER_GEN): $(BIN_DIR)
	GO111MODULE="on" go build -o $@ sigs.k8s.io/controller-tools/cmd/controller-gen

$(JB): $(BIN_DIR)
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	GO111MODULE="on" go build -o $@ github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

JSONNET_SRC = $(shell find . -type f -not -path './*vendor/*' \( -name '*.libsonnet' -o -name '*.jsonnet' \))

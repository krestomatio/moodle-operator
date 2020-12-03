CONTAINER_BUILDER ?= docker
OPERATOR_NAME ?= m4e-operator
# Image
REGISTRY_PATH ?= quay.io/krestomatio
IMAGE_NAME ?= $(REGISTRY_PATH)/$(OPERATOR_NAME)
# requirements
OPERATOR_VERSION ?= 1.1.0
KUSTOMIZE_VERSION ?= 3.5.4
# Build
BUILD_REGISTRY_PATH ?= docker-registry.jx.krestomat.io/krestomatio/m4e-operator
BUILD_OPERATOR_NAME ?= m4e-operator
BUILD_IMAGE_NAME ?= $(REGISTRY_PATH)/$(OPERATOR_NAME)
BUILD_VERSION ?= $(shell git rev-parse HEAD 2> /dev/null  || echo)
# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default
# skopeo
SKOPEO_SRC_TLS ?= True
SKOPEO_DEST_TLS ?= true
# Release
GIT_REMOTE ?= origin
# Current Operator version
VERSION ?= 0.2.4
# Default bundle image tag
BUNDLE_IMG ?= $(IMAGE_NAME)-bundle:$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_NAME):$(VERSION)

all: image-build

# Run against the configured Kubernetes cluster in ~/.kube/config
run: ansible-operator
	$(ANSIBLE_OPERATOR) run

# Install CRDs into a cluster
install: kustomize
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall: kustomize
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: kustomize
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | kubectl delete -f -

# Build the container image
image-build:
	$(CONTAINER_BUILDER) build . -t ${IMG}

# Push the container image
image-push:
	$(CONTAINER_BUILDER) push ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )

kustomize:
ifeq (, $(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_$(OS)_$(ARCH).tar.gz | tar xzf - -C bin/ ;\
	}
KUSTOMIZE=$(realpath ./bin/kustomize)
else
KUSTOMIZE=$(shell which kustomize)
endif

ansible-operator:
ifeq (, $(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v$(OPERATOR_VERSION)/ansible-operator-v$(OPERATOR_VERSION)-$(ARCHOPER)-$(OSOPER) ;\
	mv ansible-operator-v$(OPERATOR_VERSION)-$(ARCHOPER)-$(OSOPER) ./bin/ansible-operator ;\
	chmod +x ./bin/ansible-operator ;\
	}
ANSIBLE_OPERATOR=$(realpath ./bin/ansible-operator)
else
ANSIBLE_OPERATOR=$(shell which ansible-operator)
endif

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	$(CONTAINER_BUILDER) build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

# test with molecule
.PHONY: molecule
molecule:
	molecule $(MOLECULE_SEQUENCE) -s $(MOLECULE_SCENARIO)

# Pullrequest pipeline
.PHONY: pr
pr:	VERSION = $(BUILD_VERSION)
	export OPERATOR_IMAGE ?= $(IMG)
pr: image-build image-push molecule

# Release pipeline
.PHONY: release
release: promote
	git add Makefile
	git commit -m "Release version $(VERSION)" -m "[skip.ci]"
	git tag v$(VERSION)
	# git push $(GIT_REMOTE) $(GIT_BRANCH) --tags

# copy image using skopeo
promote:
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMAGE_NAME):$(BUILD_VERSION) docker://$(IMAGE_NAME):$(VERSION)

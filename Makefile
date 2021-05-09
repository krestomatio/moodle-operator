CONTAINER_BUILDER ?= docker
OPERATOR_NAME ?= m4e-operator
REPO_NAME ?= m4e-operator
REPO_OWNER ?= krestomatio
VERSION ?= 0.2.8

# Image
REGISTRY ?= quay.io
REGISTRY_PATH ?= $(REGISTRY)/$(REPO_OWNER)
IMG_NAME ?= $(REGISTRY_PATH)/$(OPERATOR_NAME)
IMG ?= $(IMG_NAME):$(VERSION)

# requirements
OPERATOR_VERSION ?= 1.1.0
KUSTOMIZE_VERSION ?= 3.5.4

# JX
JOB_NAME ?= pr
PULL_NUMBER ?= 0
BUILD_ID ?= 0

# Build
BUILD_REGISTRY_PATH ?= docker-registry.jx.krestomat.io/krestomatio
BUILD_OPERATOR_NAME ?= $(OPERATOR_NAME)
BUILD_IMG_NAME ?= $(BUILD_REGISTRY_PATH)/$(BUILD_OPERATOR_NAME)
ifeq ($(JOB_NAME),release)
BUILD_VERSION ?= $(shell git rev-parse HEAD^2 &>/dev/null && git rev-parse HEAD^2 || echo)
else
BUILD_VERSION ?= $(shell git rev-parse HEAD 2> /dev/null  || echo)
endif

# CI
SKIP_MSG := skip.ci
RUN_PIPELINE ?= $(shell git log -1 --pretty=%B | cat | grep -q "\[$(SKIP_MSG)\]" && echo || echo 1)
ifeq ($(RUN_PIPELINE),)
SKIP_PIPELINE = true
$(info RUN_PIPELINE not set, skipping...)
endif
ifeq ($(BUILD_VERSION),)
SKIP_PIPELINE = true
$(info BUILD_VERSION not set, skipping...)
endif
ifeq ($(origin PULL_BASE_SHA),undefined)
CHANGELOG_FROM ?= HEAD~1
else
CHANGELOG_FROM ?= $(PULL_BASE_SHA)
endif
ifeq ($(origin PULL_PULL_SHA),undefined)
COMMITLINT_TO ?= HEAD
else
COMMITLINT_TO ?= $(PULL_PULL_SHA)
endif

# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default
export OPERATOR_IMAGE ?= $(IMG)
export TEST_OPERATOR_NAMESPACE ?= m4e-$(JOB_NAME)-$(PULL_NUMBER)-$(BUILD_ID)

# skopeo
SKOPEO_SRC_TLS ?= True
SKOPEO_DEST_TLS ?= true

# Release
GIT_REMOTE ?= origin
GIT_BRANCH ?= master
GIT_ADD_FILES ?= Makefile
CHANGELOG_FILE ?= CHANGELOG.md

# Default bundle image tag
BUNDLE_IMG ?= $(IMG_NAME)-bundle:$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

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
	$(CONTAINER_BUILDER) build . -t $(IMG)

# Push the container image
image-push:
	$(CONTAINER_BUILDER) push $(IMG)

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

# CI
ifeq ($(origin SKIP_PIPELINE),undefined)
## Pullrequest pipeline
.PHONY: pr
pr: IMG = $(BUILD_IMG_NAME):$(BUILD_VERSION)
pr: image-build image-push molecule

### lint
.PHONY: lint
lint: MOLECULE_SEQUENCE = lint
lint: molecule

### check
.PHONY: check
check: MOLECULE_SEQUENCE = check
check: pr

### test k8s
.PHONY: k8s
k8s: pr

### Test with molecule
.PHONY: molecule
molecule:
	molecule $(MOLECULE_SEQUENCE) -s $(MOLECULE_SCENARIO)

## Release pipeline
.PHONY: release
release: promote git

### Changelog using jx
.PHONY: changelog
changelog:
ifeq (0, $(shell test -d  "charts/$(REPO_NAME)"; echo $$?))
	sed -i "s/^version:.*/version: $(VERSION)/" charts/$(REPO_NAME)/Chart.yaml
	sed -i "s/tag:.*/tag: $(VERSION)/" charts/$(REPO_NAME)/values.yaml
	sed -i "s@repository:.*@repository: $(IMG_NAME)@" charts/$(REPO_NAME)/values.yaml
	git add charts/
else
	echo no charts
endif
	jx changelog create --verbose --version=$(VERSION) --rev=$(CHANGELOG_FROM) --output-markdown=$(CHANGELOG_FILE) --update-release=false
	git add $(CHANGELOG_FILE)

### Release pipeline
.PHONY: git
git:
	git add $(GIT_ADD_FILES)
	git commit -m "chore(release): $(VERSION)" -m "[$(SKIP_MSG)]"
	git tag v$(VERSION)
	git push $(GIT_REMOTE) $(GIT_BRANCH) --tags

### copy image using skopeo
.PHONY: promote
promote:
	# full version
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(VERSION)
	# major + minor
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(word 1,$(subst ., ,$(VERSION))).$(word 2,$(subst ., ,$(VERSION)))
	# major
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(word 1,$(subst ., ,$(VERSION)))
else
$(info SKIP_PIPELINE set:)
## pr
pr:
	$(info skipping pr...)

lint:
	$(info skipping lint...)

## release
changelog:
	$(info skipping changelog...)

release:
	$(info skipping release...)
endif

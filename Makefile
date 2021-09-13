CONTAINER_BUILDER ?= docker
OPERATOR_SHORTNAME ?= m4e
OPERATOR_NAME ?= $(OPERATOR_SHORTNAME)-operator
REPO_NAME ?= $(OPERATOR_SHORTNAME)-operator
REPO_OWNER ?= krestomatio
VERSION ?= 0.3.14

# Image
REGISTRY ?= quay.io
REGISTRY_PATH ?= $(REGISTRY)/$(REPO_OWNER)
IMG_NAME ?= $(REGISTRY_PATH)/$(OPERATOR_NAME)
IMG ?= $(IMG_NAME):$(VERSION)

# requirements
OPERATOR_VERSION ?= 1.11.0
KUSTOMIZE_VERSION ?= 4.1.3
OPM_VERSION ?= 1.15.1

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

# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default
export OPERATOR_IMAGE ?= $(IMG)
export TEST_OPERATOR_NAMEPREFIX ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(BUILD_ID)-
export TEST_OPERATOR_NAMESPACE ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(BUILD_ID)-ns
export TEST_OPERATOR_OMIT_CRDS_DELETION ?= true
export TEST_OPERATOR_SHORTNAME ?= $(OPERATOR_SHORTNAME)

# skopeo
SKOPEO_SRC_TLS ?= True
SKOPEO_DEST_TLS ?= true

# Release
GIT_REMOTE ?= origin
GIT_BRANCH ?= master
GIT_ADD_FILES ?= Makefile
CHANGELOG_FILE ?= CHANGELOG.md

# krestomatio ansible collection
COLLECTION_VERSION ?= 0.0.39
export COLLECTION_FILE ?= krestomatio-k8s-$(COLLECTION_VERSION).tar.gz

# CHANNELS define the bundle channels used in the bundle.
# Add a new line here if you would like to change its default config. (E.g CHANNELS = "candidate,fast,stable")
# To re-generate a bundle for other specific channels without changing the standard setup, you can:
# - use the CHANNELS as arg of the bundle target (e.g make bundle CHANNELS=candidate,fast,stable)
# - use environment variables to overwrite this value (e.g export CHANNELS="candidate,fast,stable")
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif

# DEFAULT_CHANNEL defines the default channel used in the bundle.
# Add a new line here if you would like to change its default config. (E.g DEFAULT_CHANNEL = "stable")
# To re-generate a bundle for any other default channel without changing the default setup, you can:
# - use the DEFAULT_CHANNEL as arg of the bundle target (e.g make bundle DEFAULT_CHANNEL=stable)
# - use environment variables to overwrite this value (e.g export DEFAULT_CHANNEL="stable")
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# IMAGE_TAG_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
#
# For example, running 'make bundle-build bundle-push catalog-build catalog-push' will build and push both
# krestomat.io/m4e-operator-bundle:$VERSION and krestomat.io/m4e-operator-catalog:$VERSION.
IMAGE_TAG_BASE ?= $(IMG_NAME)

# BUNDLE_IMG defines the image:tag used for the bundle.
# You can use it as an arg. (E.g make bundle-build BUNDLE_IMG=<some-registry>/<project-name-bundle>:<tag>)
BUNDLE_IMG ?= $(IMAGE_TAG_BASE)-bundle:v$(VERSION)

all: collection-build image-build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: git
git: ## Git add, commit, tag and push
	git add $(GIT_ADD_FILES)
	git commit -m "chore(release): $(VERSION)" -m "[$(SKIP_MSG)]"
	git tag v$(VERSION)
	git push $(GIT_REMOTE) $(GIT_BRANCH) --tags

.PHONY: molecule
molecule: ## Test with molecule
	molecule $(MOLECULE_SEQUENCE) -s $(MOLECULE_SCENARIO)

.PHONY: skopeo-copy
skopeo-copy: ## Copy images using skopeo
	# full version
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(VERSION)
	# major + minor
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(word 1,$(subst ., ,$(VERSION))).$(word 2,$(subst ., ,$(VERSION)))
	# major
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG_NAME):$(BUILD_VERSION) docker://$(IMG_NAME):$(word 1,$(subst ., ,$(VERSION)))

##@ JX

.PHONY: jx-changelog
jx-changelog: ## Generate changelog file using jx
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

##@ Build

run: ansible-operator ## Run against the configured Kubernetes cluster in ~/.kube/config
	ANSIBLE_ROLES_PATH="$(ANSIBLE_ROLES_PATH):$(shell pwd)/roles" $(ANSIBLE_OPERATOR) run

image-build: ## Build container image with the manager.
	$(CONTAINER_BUILDER) build . -t $(IMG) \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)

image-push: ## Push container image with the manager.
	$(CONTAINER_BUILDER) push $(IMG)

collection-build: ## Build krestomatio collection from path or git to file
	rm -rf *.tar.gz /tmp/ansible-collection-k8s*
ifeq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
	cp -rp ~/.ansible/collections/ansible_collections/krestomatio/k8s /tmp/ansible-collection-k8s-$(COLLECTION_VERSION)
else
	curl -L https://github.com/krestomatio/ansible-collection-k8s/archive/v$(COLLECTION_VERSION).tar.gz | tar xzf - -C /tmp/
endif
	ansible-galaxy collection build --force /tmp/ansible-collection-k8s-$(COLLECTION_VERSION)
	test -f $(COLLECTION_FILE) || mv krestomatio-k8s-*.tar.gz $(COLLECTION_FILE)
ifneq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
	mkdir -p $${HOME}/.ansible/collections/ansible_collections/krestomatio/
	cp -rp /tmp/ansible-collection-k8s-$(COLLECTION_VERSION) ~/.ansible/collections/ansible_collections/krestomatio/k8s
endif

ifneq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
collection-install: collection-build
collection-install:
	mkdir -p $${HOME}/.ansible/collections/ansible_collections/krestomatio/
	cp -rp /tmp/ansible-collection-k8s-$(COLLECTION_VERSION) ~/.ansible/collections/ansible_collections/krestomatio/k8s
else
collection-install: ## Install krestomatio collection from git
	$(info krestomatio collection already installed...)
endif

##@ Deployment

install: kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

uninstall: kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

deploy: kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/default | kubectl delete -f -

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')

.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

.PHONY: ansible-operator
ANSIBLE_OPERATOR = $(shell pwd)/bin/ansible-operator
ansible-operator: ## Download ansible-operator locally if necessary, preferring the $(pwd)/bin path over global if both exist.
ifeq (,$(wildcard $(ANSIBLE_OPERATOR)))
ifeq (,$(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(ANSIBLE_OPERATOR)) ;\
	curl -sSLo $(ANSIBLE_OPERATOR) https://github.com/operator-framework/operator-sdk/releases/download/v$(OPERATOR_VERSION)/ansible-operator_$(OS)_$(ARCH) ;\
	chmod +x $(ANSIBLE_OPERATOR) ;\
	}
else
ANSIBLE_OPERATOR = $(shell which ansible-operator)
endif
endif

.PHONY: bundle
bundle: kustomize ## Generate bundle manifests and metadata, then validate generated files.
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	operator-sdk bundle validate ./bundle

.PHONY: bundle-build
bundle-build: ## Build the bundle image.
	$(CONTAINER_BUILDER) build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

.PHONY: bundle-push
bundle-push: ## Push the bundle image.
	$(MAKE) image-push IMG=$(BUNDLE_IMG)

.PHONY: opm
OPM = ./bin/opm
opm: ## Download opm locally if necessary.
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v$(OPM_VERSION)/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif

# A comma-separated list of bundle images (e.g. make catalog-build BUNDLE_IMGS=example.com/operator-bundle:v0.1.0,example.com/operator-bundle:v0.2.0).
# These images MUST exist in a registry and be pull-able.
BUNDLE_IMGS ?= $(BUNDLE_IMG)

# The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=example.com/operator-catalog:v0.2.0).
CATALOG_IMG ?= $(IMAGE_TAG_BASE)-catalog:v$(VERSION)

# Set CATALOG_BASE_IMG to an existing catalog image tag to add $BUNDLE_IMGS to that image.
ifneq ($(origin CATALOG_BASE_IMG), undefined)
FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
endif

# Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'.
# This recipe invokes 'opm' in 'semver' bundle add mode. For more information on add modes, see:
# https://github.com/operator-framework/community-operators/blob/7f1438c/docs/packaging-operator.md#updating-your-existing-operator
.PHONY: catalog-build
catalog-build: opm ## Build a catalog image.
	$(OPM) index add --container-tool $(CONTAINER_BUILDER) --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)

# Push the catalog image.
.PHONY: catalog-push
catalog-push: ## Push a catalog image.
	$(MAKE) image-push IMG=$(CATALOG_IMG)

# CI tasks
## start if not SKIP_PIPELINE
ifeq ($(origin SKIP_PIPELINE),undefined)

##@ Pullrequest

.PHONY: lint
lint: MOLECULE_SEQUENCE = lint
lint: molecule ## Run lint tasks

.PHONY: k8s
k8s: pr ## Run k8s tasks

.PHONY: pr
pr: IMG = $(BUILD_IMG_NAME):$(BUILD_VERSION)
pr: collection-build image-build image-push molecule ## Run pr tasks

##@ Release

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: skopeo-copy ## Run release tasks

.PHONY: promote
promote: git ## Promote release

## else if not SKIP_PIPELINE
else
$(info SKIP_PIPELINE set:)
## Pull request
pr:
	$(info skipping pr...)

lint:
	$(info skipping lint...)

k8s:
	$(info skipping k8s...)

## Release
changelog:
	$(info skipping changelog...)

release:
	$(info skipping release...)

promote:
	$(info skipping promote...)

## end if not SKIP_PIPELINE
endif

PROJECT_SHORTNAME ?= m4e
VERSION ?= 0.4.6
COLLECTION_VERSION ?= 0.1.13
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

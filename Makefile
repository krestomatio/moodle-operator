PROJECT_SHORTNAME ?= m4e
VERSION ?= 0.4.2
COLLECTION_VERSION ?= 0.1.9
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.4.16
COLLECTION_VERSION ?= 0.1.27
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

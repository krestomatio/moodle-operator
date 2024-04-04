PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.6
COLLECTION_VERSION ?= 0.4.8
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

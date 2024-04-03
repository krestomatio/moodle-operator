PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.5
COLLECTION_VERSION ?= 0.4.7
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

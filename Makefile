PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.61
COLLECTION_VERSION ?= 0.4.1
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

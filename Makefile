PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.3
COLLECTION_VERSION ?= 0.4.4
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

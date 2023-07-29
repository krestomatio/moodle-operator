PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.24
COLLECTION_VERSION ?= 0.3.30
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

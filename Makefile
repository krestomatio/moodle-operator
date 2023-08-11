PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.35
COLLECTION_VERSION ?= 0.3.41
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

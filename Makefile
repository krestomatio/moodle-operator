PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.40
COLLECTION_VERSION ?= 0.3.46
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.39
COLLECTION_VERSION ?= 0.3.45
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

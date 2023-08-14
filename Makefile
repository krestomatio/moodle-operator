PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.5.45
COLLECTION_VERSION ?= 0.3.50
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator

include hack/mk/main.mk

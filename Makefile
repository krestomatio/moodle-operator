PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.25
COLLECTION_VERSION ?= 0.4.21
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator
COMMUNITY_OPERATOR_NAME ?= moodle-operator

include hack/mk/main.mk

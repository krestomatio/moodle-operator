PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.18
COLLECTION_VERSION ?= 0.4.13
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator
COMMUNITY_OPERATOR_NAME ?= moodle-operator

include hack/mk/main.mk

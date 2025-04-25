PROJECT_SHORTNAME ?= moodle
VERSION ?= 0.6.26
COLLECTION_VERSION ?= 0.4.26
OPERATOR_TYPE ?= ansible
PROJECT_TYPE ?= $(OPERATOR_TYPE)-operator
COMMUNITY_OPERATOR_NAME ?= moodle-operator

include hack/mk/main.mk

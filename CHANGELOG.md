## Changes

### New Features

* create a service account for the operator by default (Job Céspedes Ortiz)
* add option for tolerations (Job Céspedes Ortiz)
* add option to set postgres replicas to 0 (Job Céspedes Ortiz)
* add moodle checks to subresource status (Job Céspedes Ortiz)

### Bug Fixes

* add workaround for k8s status issue (Job Céspedes Ortiz)
* add workaround for downloading krestomatio collection (Job Céspedes Ortiz)
* replace nginx command (Job Céspedes Ortiz)

### Code Refactoring

* reduce sample files (Job Céspedes Ortiz)
* rename role name (Job Céspedes Ortiz)
* fix github templates (Job Céspedes Ortiz)
* remove unnecessary tasks in molecule (Job Céspedes Ortiz)
* move m4e role to collection (Job Céspedes Ortiz)
* change how kubectl is installed (Job Céspedes Ortiz)
* remove common templates and refactor (Job Céspedes Ortiz)
* add option for extra label, annotations in deply spec (Job Céspedes Ortiz)
* set fsgroup default to runasuser (Job Céspedes Ortiz)
* do not use resource limit by default (Job Céspedes Ortiz)
* use imagePullPolicy IfNotPresent in all deployments (Job Céspedes Ortiz)
* nginx: add variable for ingress path (Job Céspedes Ortiz)
* use template to sync config.php instead of copy (Job Céspedes Ortiz)

### Chores

* release: 0.2.10 (krestomatio-cibot)
* operator: update operator version to 1.7.2 (Job Céspedes Ortiz)
* update README.md (Job Céspedes Ortiz)

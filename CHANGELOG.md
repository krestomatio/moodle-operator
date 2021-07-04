## Changes

### New Features

* create a service account for the operator by default (Job Céspedes Ortiz)
* add option for tolerations (Job Céspedes Ortiz)
* add option to set postgres replicas to 0 (Job Céspedes Ortiz)
* add moodle checks to subresource status (Job Céspedes Ortiz)
* add created condition (Job Céspedes Ortiz)
* add routines to get instance status properties (Job Céspedes Ortiz)
* customize m4e inventory plugin from k8s collection (Job Céspedes Ortiz)
* add inventory plugin from k8s collection for customization (Job Céspedes Ortiz)
* add option to wait for ingress ip (Job Céspedes Ortiz)
* add gke sample (Job Céspedes Ortiz)
* add instantiated condition (Job Céspedes Ortiz)
* add external status notification (Job Céspedes Ortiz)
* add ready status (Job Céspedes Ortiz)

### Bug Fixes

* add workaround for k8s status issue (Job Céspedes Ortiz)
* add workaround for downloading krestomatio collection (Job Céspedes Ortiz)
* replace nginx command (Job Céspedes Ortiz)
* adjust php script to collect instance properties (Job Céspedes Ortiz)
* moodle: cron job readiness var (Job Céspedes Ortiz)
* moodle: change order of conditional when cleaning up (Job Céspedes Ortiz)

### Code Refactoring

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
* add container name variable (Job Céspedes Ortiz)
* remove moodle jobs and pods cleanup (Job Céspedes Ortiz)
* move moodle tasks (Job Céspedes Ortiz)
* simplify status conditions (Job Céspedes Ortiz)
* change osdk to m4e references (Job Céspedes Ortiz)
* move tasks releted to k8s module to a folder (Job Céspedes Ortiz)
* add wait to all deployments (Job Céspedes Ortiz)
* use default variables for name and namespace (Job Céspedes Ortiz)

### Chores

* operator: update operator version to 1.7.2 (Job Céspedes Ortiz)
* update README.md (Job Céspedes Ortiz)
* release: 0.2.9 (krestomatio-cibot)
* lint code (Job Céspedes Ortiz)

## Changes

### New Features

* php-fpm: set default process control timeout (Job Céspedes Ortiz)
* postgres: set option to log to stderr by default (Job Céspedes Ortiz)

### Bug Fixes

* add config.php ssl proxy option when tls enable (Job Céspedes Ortiz)
* set fsgroup in nginx same as php-fpm (Job Céspedes Ortiz)
* add conditional for moodle_app in nginx deployment (Job Céspedes Ortiz)

### Code Refactoring

* adjust nginx ingress rule (Job Céspedes Ortiz)
* use httpget probes for nginx (Job Céspedes Ortiz)
* change ingress api version (Job Céspedes Ortiz)
* add condition for secret name in expose tls(https) (Job Céspedes Ortiz)

### Documentation

* update tasks in README.md (Job Céspedes Ortiz)

### Chores

* release: 0.2.7 (krestomatio-cibot)

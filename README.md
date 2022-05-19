This is a Moodle Operator for Kubernetes or OKD (Openshift). It uses Ansible Operator SDK.

## TODO
The operator is in alpha stage. There is work in progress for:
- [ ] Publish operator
- [ ] Documentation
  - [ ] Code of conduct
  - [ ] Conventions
  - [ ] Architecture
  - [ ] Containers
  - [ ] Features
  - [ ] Installation
  - [ ] Operation
- [ ] CI
  - [ ] Tests
    - [ ] Operator platforms
      - [X] Minikube
      - [X] GKE
      - [ ] AWS
      - [X] OKD
    - [ ] Moodle unit test
    - [ ] Deployment
    - [ ] Performance
- [ ] Operator life cycle manager

## Prerequisites
- A **database instance and its credentials**. One can be created using [Postgres-operator](https://github.com/krestomatio/postgres-operator). If so, just set `moodle_postgres_meta_name` to the Postgres CR name created in the same namespace. Credentials will be fetch with that variable. Ex, for a Postgres CR named 'postgres-sample': `moodle_postgres_meta_name: postgres-sample`. Otherwise, you need to get a db instance and provide the following variables for a db connection:
  - `moodle_config_dbhost`
  - `moodle_config_dbname`
  - `moodle_config_dbuser`
  - `moodle_config_dbpass`

## Install
Check out the [sample CR](config/samples/m4e_v1alpha1_m4e.yaml). Follow the next steps to first install the M4e Operator:
```bash
# meet the prerequisites

# install the operator
make deploy

# modify config/samples/m4e_v1alpha1_m4e.yaml to include db connection and credentials
nano config/samples/m4e_v1alpha1_m4e.yaml

# add a M4e object to instance a default moodle. The default image is inmutable. Extra plugins will be lost after pod replacement.
kubectl apply -f config/samples/m4e_v1alpha1_m4e.yaml

# follow/check M4e operator logs
kubectl -n m4e-operator-system logs -l control-plane=controller-manager -c manager  -f

# follow sample CR status
kubectl get M4e m4e-sample -o yaml -w
```

## Uninstall
Follow the next steps to uninstall it.
```bash
# delete the M4e object
# CAUTION with data loss
kubectl delete -f config/samples/m4e_v1alpha1_m4e.yaml

# uninstall the operator
make undeploy
```

## Admin password
To renew an admin's password, you can set a new value to `moodle_new_adminpass_hash` in M4e CR. Its value has to be a BCrypt compatible hash. You can generate one in the command line using python. For example, to generate a hash for the password 'changeme':
```bash
admin_pass=changeme
python -c "import bcrypt; print(bcrypt.hashpw(b'$admin_pass', bcrypt.gensalt(rounds=10)).decode('ascii'))"
```


## Want to contribute?
* Use github issues to report bugs, send enhancement, new feature requests and questions
* Join [our telegram group](https://t.me/m4e_operator)

## Suggested readings when developing operators

[Operator SDK](https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible)

[O’Reilly: Kubernetes Operators ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-operators-automation-ebook)

[O’Reilly: Kubernetes Patterns ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-patterns-cloud-native-apps)

This is a Moodle Operator for Kubernetes or OKD (Openshift). It uses Ansible Operator SDK.

## TODO
The operator is in alpha stage. There is work in progress for:
- [ ] Documentation
  - [ ] Code of conduct
  - [ ] Conventions
  - [ ] Architecture
  - [ ] Containers
  - [ ] Features
  - [x] Installation
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
- [ ] Publish operator
  - [ ] Operator life cycle manager

## Prerequisites
- A **database instance and its credentials**. One can be created using [Postgres-operator](https://github.com/krestomatio/postgres-operator). If so, just set `moodle_postgres_meta_name` to the Postgres CR name created in the same namespace. Credentials will be fetch with that variable. Ex, for a Postgres CR named 'postgres-sample': `moodle_postgres_meta_name: postgres-sample`. Otherwise, you need to get a db instance and provide the following variables for a db connection:
  - `moodle_config_dbhost`
  - `moodle_config_dbname`
  - `moodle_config_dbuser`
  - `moodle_config_dbpass`

## Install
Check out the [sample CR](config/samples/m4e_v1alpha1_moodle.yaml). Follow the next steps to first install the Moodle Operator:
```bash
# meet the prerequisites

# install the operator
make deploy

# modify config/samples/m4e_v1alpha1_moodle.yaml to include db connection and credentials
nano config/samples/m4e_v1alpha1_moodle.yaml

# add a Moodle object to instance a default moodle. The default image is inmutable. Extra plugins will be lost after pod replacement.
kubectl apply -f config/samples/m4e_v1alpha1_moodle.yaml

# follow/check Moodle operator logs
kubectl -n moodle-operator-system logs -l control-plane=controller-manager -c manager  -f

# follow sample CR status
kubectl get Moodle moodle-sample -o yaml -w
```

## Uninstall
Follow the next steps to uninstall it.
```bash
# delete the Moodle object
# CAUTION with data loss
kubectl delete -f config/samples/m4e_v1alpha1_moodle.yaml

# uninstall the operator
make undeploy
```

## Custom image
An immutable image approach is followed. See [how the image is built and how to customize it](https://github.com/krestomatio/container_builder/tree/master/moodle#custom-builds), when needed.

## Want to contribute?
* Use github issues to report bugs, send enhancement, new feature requests and questions
* Join [our telegram group](https://t.me/moodle_operator)

## Admin password
To renew an admin's password, you can set a new value to `moodle_new_adminpass_hash` in Moodle CR. Its value has to be a BCrypt compatible hash. You can generate one in the command line using python. For example, to generate a hash for the password 'changeme':
```bash
admin_pass=changeme
python -c "import bcrypt; print(bcrypt.hashpw(b'$admin_pass', bcrypt.gensalt(rounds=10)).decode('ascii'))"
```

## Suggested readings when developing operators

[Operator SDK](https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible)

[O’Reilly: Kubernetes Operators ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-operators-automation-ebook)

[O’Reilly: Kubernetes Patterns ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-patterns-cloud-native-apps)

This is a Moodle Operator for Kubernetes or Openshift. It is based on Ansible operator sdk.

## TODO
The operator is in alpha stage. There is work in progress for:
- [X] Publish container images
- [ ] Centos replacement: Centos Stream or waiting for Rocky Linux?
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
  - [X] Templates
    - [X] Issues
    - [X] Pullrequest
  - [X] Pipelines
  - [ ] Tests
    - [ ] Operator test
      - [X] K8s
      - [ ] Okd
    - [ ] Moodle unit test
    - [ ] Deployment
    - [ ] Performance
- [ ] Operator life cycle manager

## Install
```bash
# install the operator
make deploy

# add a M4e object to instance a default moodle. The default image is inmutable. Extra plugins will be lost after pod replacement.
kubectl apply -f config/samples/m4e_v1alpha1_m4e.yaml
```
More instructions could be found in the [Ansible Operator Tutorial](https://sdk.operatorframework.io/docs/building-operators/ansible/tutorial/)

## Uninstall
```bash
# delete the M4e object
# CAUTION with data loss
kubectl delete -f config/samples/m4e_v1alpha1_m4e.yaml

# uninstall the operator
make undeploy
```

## Suggested readings when developing operators

[Operator SDK](https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible)

[O’Reilly: Kubernetes Operators ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-operators-automation-ebook)

[O’Reilly: Kubernetes Patterns ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-patterns-cloud-native-apps)

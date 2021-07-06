This is a Moodle Operator for Kubernetes or OKD (Openshift). It uses Ansible Operator SDK.

## TODO
The operator is in alpha stage. There is work in progress for:
- [X] Publish container images
- [X] Centos replacement: Centos Stream or waiting for Rocky Linux? Centos Stream was chosen
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
    - [ ] Operator platforms
      - [X] Minikube
      - [X] GKE
      - [ ] AWS
      - [X] OKD
    - [ ] Moodle unit test
    - [ ] Deployment
    - [ ] Performance
- [ ] Operator life cycle manager

## Install
Check out the [sample CR](config/samples/m4e_v1alpha1_m4e.yaml). Follow the next steps to first install the M4e Operator:
```bash
# install the operator
make deploy

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

## Want to contribute?
* Use github issues to report bugs, send enhancement, new feature requests and questions
* Join [our telegram group](https://t.me/m4e_operator)

## Suggested readings when developing operators

[Operator SDK](https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible)

[O’Reilly: Kubernetes Operators ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-operators-automation-ebook)

[O’Reilly: Kubernetes Patterns ebook](https://www.redhat.com/es/resources/oreilly-kubernetes-patterns-cloud-native-apps)

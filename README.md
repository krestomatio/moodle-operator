# https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible
# install operator-sdk
# pip docker openshift molecule

operator-sdk new m4e-operator --api-version=m4e.krestomatio.com/v1alpha1 --kind=M4e --type=ansible --git-init --generate-playbook

cd new m4e-operator

git add .
git commit -m "Initial"

# build image
operator-sdk build quay.io/krestomatio/m4e-operator:v0.0.1
docker push quay.io/krestomatio/m4e-operator:v0.0.1

# replace image placeholder
sed -i "s@REPLACE_IMAGE@quay.io/krestomatio/m4e-operator@g" deploy/operator.yaml

# create new project
oc new-project m4e-project
oc create -f deploy/crds/m4e.krestomatio.com_m4es_crd.yaml

oc create -f deploy/service_account.yaml
oc create -f deploy/role.yaml
oc create -f deploy/role_binding.yaml
oc create -f deploy/operator.yaml

# modify size inside file
oc apply -f deploy/crds/m4e.krestomatio.com_v1alpha1_m4e_cr.yaml

# clean
oc delete -f deploy/crds/m4e.krestomatio.com_v1alpha1_m4e_cr.yaml
oc delete -f deploy/operator.yaml
oc delete -f deploy/role_binding.yaml
oc delete -f deploy/role.yaml
oc delete -f deploy/service_account.yaml
oc delete -f deploy/crds/m4e.krestomatio.com_m4es_crd.yaml
oc delete project m4e-project

# molecule

## create and converge
molecule converge -s test-local

## login
molecule login -s test-local -h kind-test-local

## pods
kubectl -n osdk-test get pods

## logs
pod=$(kubectl -n osdk-test get pods --no-headers=true -o custom-columns=NAME:.metadata.name | grep operator)
kubectl -n osdk-test logs --tail 1 --follow $pod

## destroy
molecule converge --all

# https://docs.openshift.com/container-platform/4.2/operators/operator_sdk/osdk-ansible.html#osdk-building-ansible-operator_osdk-ansible
# install operator-sdk
# pip docker openshift molecule

operator-sdk new m4e-operator --api-version=m4e.krestomatio.com/v1alpha1 --kind=M4e --type=ansible --git-init --generate-playbook

cd new m4e-operator

git add .
git commit -m "Initial"

# replace image placeholder
sed -i "s@REPLACE_IMAGE@quay.io/krestomatio/m4e-operator@g" deploy/operator.yaml

# build image
operator-sdk build quay.io/krestomatio/m4e-operator:v0.0.1
docker push quay.io/krestomatio/m4e-operator:v0.0.1

# crc registry
oc extract secret/router-ca --keys=tls.crt -n openshift-ingress-operator --confirm
sudo mv tls.crt /etc/docker/certs.d/default-route-openshift-image-registry.apps-crc.testing/
docker login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing

oc new-project osdk-test
operator-sdk build default-route-openshift-image-registry.apps-crc.testing/osdk-test/m4e-operator
docker push default-route-openshift-image-registry.apps-crc.testing/osdk-test/m4e-operator

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

## verify - create objects
molecule verify -s test-local

## login
molecule login -s test-local -h kind-test-local

## pods
kubectl -n osdk-test get pods

## logs
pod=$(kubectl -n osdk-test get pods --no-headers=true -o custom-columns=NAME:.metadata.name | grep operator)
kubectl -n osdk-test logs --tail 1 --follow $pod

## cluster
export OPERATOR_IMAGE=image-registry.openshift-image-registry.svc:5000/osdk-test/m4e-operator
export CR_FILE=m4e.krestomatio.com_v1alpha1_m4e_cr_testing.yaml
molecule converge -s cluster

## destroy
molecule destroy --all

# moodle
## cli installation
app_name=example-m4e
php admin/cli/install.php --lang="en"  \
    --wwwroot="http://${app_name}-osdk-test.apps-crc.testing" \
    --dataroot="/var/moodledata" \
    --dbtype="pgsql" \
    --dbhost="${app_name}-postgres" \
    --dbname="moodle" \
    --dbuser="user" \
    --dbpass="secret" \
    --fullname="Test moodle_php" \
    --shortname="Test" \
    --summary="Summary" \
    --adminuser="admin" \
    --adminpass="secret" \
    --adminemail="test@test.com" \
    --agree-license \
    --non-interactive

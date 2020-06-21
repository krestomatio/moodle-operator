FROM quay.io/operator-framework/ansible-operator:v0.17.0

# Install kubectl.
COPY --from=lachlanevenson/k8s-kubectl:v1.18.3 /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
COPY playbook.yml ${HOME}/playbook.yml

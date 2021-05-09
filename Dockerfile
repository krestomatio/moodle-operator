FROM quay.io/operator-framework/ansible-operator:v1.1.0

# Install kubectl. It is needed for ansible kubectl inventory.
COPY --from=lachlanevenson/k8s-kubectl:v1.19.3 /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
COPY plugins/inventory/m4e.py ${HOME}/.ansible/plugins/inventory/m4e.py
COPY .m4e.yml ${HOME}/.m4e.yml

ENV ANSIBLE_INVENTORY=${HOME}/.m4e.yml \
    ANSIBLE_INVENTORY_ENABLED=auto,m4e

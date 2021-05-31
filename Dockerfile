FROM quay.io/operator-framework/ansible-operator:v1.7.2

# Install kubectl
ENV KUBECTL_VERSION="1.20.7"
USER 0
RUN echo "Installing kubectl version: ${KUBECTL_VERSION}..."  && \
    curl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl
USER 1001

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY playbooks/ ${HOME}/playbooks/
COPY inventory.yml ${HOME}/inventory.yml

ENV ANSIBLE_INVENTORY=${HOME}/inventory.yml \
    ANSIBLE_INVENTORY_ENABLED=auto,krestomatio.k8s.inventory

# Install krestomatio collection and its roles
ADD https://api.github.com/repos/krestomatio/ansible-collection-k8s/git/refs/heads/master /tmp/ansible-collection-k8s.json
RUN mkdir -p ${HOME}/.ansible/collections/ansible_collections/krestomatio && \
    pushd /tmp && \
    curl -L https://github.com/krestomatio/ansible-collection-k8s/archive/master.tar.gz | tar xz && \
    mv ansible-collection-k8s-master/ ${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s && \
    popd

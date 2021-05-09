# Copyright (c) 2018 Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    name: m4e
    plugin_type: inventory
    author:
      - Job Cespedes <@jobcespedes>
      - Chris Houseknecht <@chouseknecht>
      - Fabian von Feilitzsch <@fabianvf>

    short_description: Kubernetes (K8s) inventory source for m4e operator (M4e)

    description:
      - Fetch containers using a label selector and hash to match resources with it
      - Group containers (hosts) hierarchically by CR info, pods, and app.kubernetes.io labels

    options:
      plugin:
         description: token that ensures this is a source file for the 'k8s' plugin.
         required: True
         choices: ['m4e']
      connection:
          description:
          - Optional dict of cluster connection settings. If no connection are provided, the default
            I(~/.kube/config) and active context will be used, and objects will be returned for all namespaces
            the active user is authorized to access.
          suboptions:
              name:
                  description:
                  - Optional name to assign to the cluster. If not provided, a name is constructed from the server
                    and port.
              kubeconfig:
                  description:
                  - Path to an existing Kubernetes config file. If not provided, and no other connection
                    options are provided, the OpenShift client will attempt to load the default
                    configuration file from I(~/.kube/config.json). Can also be specified via K8S_AUTH_KUBECONFIG
                    environment variable.
              context:
                  description:
                  - The name of a context found in the config file. Can also be specified via K8S_AUTH_CONTEXT environment
                    variable.
              host:
                  description:
                  - Provide a URL for accessing the API. Can also be specified via K8S_AUTH_HOST environment variable.
              api_key:
                  description:
                  - Token used to authenticate with the API. Can also be specified via K8S_AUTH_API_KEY environment
                    variable.
              username:
                  description:
                  - Provide a username for authenticating with the API. Can also be specified via K8S_AUTH_USERNAME
                    environment variable.
              password:
                  description:
                  - Provide a password for authenticating with the API. Can also be specified via K8S_AUTH_PASSWORD
                    environment variable.
              client_cert:
                  description:
                  - Path to a certificate used to authenticate with the API. Can also be specified via K8S_AUTH_CERT_FILE
                    environment variable.
                  aliases: [ cert_file ]
              client_key:
                  description:
                  - Path to a key file used to authenticate with the API. Can also be specified via K8S_AUTH_KEY_FILE
                    environment variable.
                  aliases: [ key_file ]
              ca_cert:
                  description:
                  - Path to a CA certificate used to authenticate with the API. Can also be specified via
                    K8S_AUTH_SSL_CA_CERT environment variable.
                  aliases: [ ssl_ca_cert ]
              validate_certs:
                  description:
                  - "Whether or not to verify the API server's SSL certificates. Can also be specified via
                    K8S_AUTH_VERIFY_SSL environment variable."
                  type: bool
                  aliases: [ verify_ssl ]

    requirements:
    - "python >= 2.7"
    - "openshift >= 0.6"
    - "PyYAML >= 3.11"
'''

EXAMPLES = '''
# File must be named m4e.yaml or m4e.yml

# Authenticate with token, and return all pods and services for all namespaces
plugin: m4e
connection:
  host: https://192.168.64.4:8443
  api_key: xxxxxxxxxxxxxxxx
  validate_certs: false

# Use a custom config file, and a specific context.
plugin: m4e
connection:
  kubeconfig: /path/to/config
  context: 'awx/192-168-64-4:8443/developer'
'''

import os
import json

from ansible.errors import AnsibleError
from ansible.plugins.filter.core import to_uuid
from ansible_collections.community.kubernetes.plugins.module_utils.common import K8sAnsibleMixin, HAS_K8S_MODULE_HELPER, k8s_import_exception
from ansible.plugins.inventory import BaseInventoryPlugin, Constructable, Cacheable

try:
    from openshift.dynamic.exceptions import DynamicApiError
except ImportError:
    pass


def format_dynamic_api_exc(exc):
    if exc.body:
        if exc.headers and exc.headers.get('Content-Type') == 'application/json':
            message = json.loads(exc.body).get('message')
            if message:
                return message
        return exc.body
    else:
        return '%s Reason: %s' % (exc.status, exc.reason)


class M4eInventoryException(Exception):
    pass


class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable, K8sAnsibleMixin):
    NAME = 'm4e'

    transport = 'kubectl'

    # get current directory (playbook) to infer CR meta from it, to later filter inventory
    # /tmp/ansible-operator/runner/<group>/<version>/<Kind>/<namespace>/<cr_name>/project
    # https://github.com/operator-framework/operator-sdk/blob/f298f7c92ee154a0e8123fb13398a7f21720cf0e/internal/ansible/runner/runner.go#L203
    try:
        cwd = os.getcwd()
        if "M4E_INVENTORY_CR_PLAY_DIR" in os.environ:
            cwd = os.getenv('M4E_INVENTORY_CR_PLAY_DIR')
        dir_parts = cwd.split(os.path.sep)
        cr_name = dir_parts[-2]
        cr_namespace = dir_parts[-3]
        cr_kind = dir_parts[-4]
        cr_version = dir_parts[-5]
        cr_group = dir_parts[-6]
    except Exception as cwd_exc:
        raise M4eInventoryException('Error getting CR info from cwd: %s' % cwd_exc )

    inventory_uuid = to_uuid(cr_group + cr_version + cr_kind + cr_namespace + cr_name)

    label_selector = '{0}/inventory={1}'.format(
        cr_group,
        inventory_uuid
    )

    annotation_inventory_hostvars = cr_group + '/inventory_hostvars'

    def parse(self, inventory, loader, path, cache=True):
        super(InventoryModule, self).parse(inventory, loader, path)
        cache_key = self._get_cache_prefix(path)
        config_data = self._read_config_data(path)
        self.setup(config_data, cache, cache_key)

    def setup(self, config_data, cache, cache_key):
        connection = config_data.get('connection')

        if not HAS_K8S_MODULE_HELPER:
            raise M4eInventoryException(
                "This module requires the OpenShift Python client. Try `pip install openshift`. Detail: {0}".format(k8s_import_exception)
            )

        source_data = None
        if cache and cache_key in self._cache:
            try:
                source_data = self._cache[cache_key]
            except KeyError:
                pass

        if not source_data:
            self.fetch_objects(connection)

    def fetch_objects(self, connection):
        if connection:
            if not isinstance(connection, dict):
                raise M4eInventoryException("Expecting connection to be a dictionary.")
            client = self.get_api_client(**connection)
        else:
            client = self.get_api_client()

        self.get_pods(client)

    def get_pods(self, client):
        v1_pod = client.resources.get(api_version='v1', kind='Pod')
        try:
            obj = v1_pod.get(label_selector=self.label_selector)
        except DynamicApiError as exc:
            self.display.debug(exc)
            raise M4eInventoryException('Error fetching Pod list: %s' % format_dynamic_api_exc(exc))

        if obj:
            # create default group based on:
            # <namespace>__<instance>__pods
            default_group_name = self._sanitize_group_name('{0}__{1}__{2}__pods'.format(self.cr_kind, self.cr_namespace, self.cr_name))
            self.inventory.add_group(default_group_name)
            # create ready group based on:
            # <namespace>__<instance>__pods_ready
            ready_group_name = default_group_name + '_ready'
            self.inventory.add_group(ready_group_name)

            for pod in obj.items:
                pod_name = pod.metadata.name
                pod_group_name = self._sanitize_group_name(pod_name)
                pod_groups = []
                pod_annotations = {} if not pod.metadata.annotations else dict(pod.metadata.annotations)
                pod_labels = {} if not pod.metadata.labels else dict(pod.metadata.labels)
                pod_variables = {}

                # add to default group
                self.inventory.add_group(pod_group_name)
                self.inventory.add_child(default_group_name, pod_group_name)

                if 'conditions' not in pod['status']:
                    ready = [c for c in pod['status']['conditions'] if c['type'] == 'Ready']
                    if ready and ready[0]['status'] == 'True':
                        self.inventory.add_child(ready_group_name, pod_group_name)

                # create pod groups from labels
                for key, value in pod_labels.items():
                    if 'app.kubernetes.io' in key:
                        group_name = self._sanitize_group_name('{0}__{1}__pods'.format(key.split('/')[1], value))
                        if group_name not in pod_groups:
                            pod_groups.append(group_name)
                        self.inventory.add_group(group_name)
                        self.inventory.add_child(group_name, pod_group_name)

                # save variables from annotation
                if self.annotation_inventory_hostvars in pod_annotations:
                    annotation_inventory_hostvars_value = pod_annotations[self.annotation_inventory_hostvars]
                    del pod_annotations[self.annotation_inventory_hostvars]
                    try:
                        pod_variables = json.loads(annotation_inventory_hostvars_value)
                    except ValueError as e:
                        raise M4eInventoryException('Error getting variables from annotation: %s' % e)

                if not pod.status.containerStatuses:
                    continue

                for container in pod.status.containerStatuses:
                    # add each pod_container to the pod groups
                    container_name = '{0}__{1}'.format(pod.metadata.name, container.name)
                    container_group_name = self._sanitize_group_name(container.name)
                    # add container as host to pod group
                    self.inventory.add_host(container_name, pod_group_name)
                    # add container group and add it as child of pod group
                    self.inventory.add_group(container_group_name)
                    self.inventory.add_child(container_group_name, container_name)

                    # Add hostvars
                    self.inventory.set_variable(container_name, 'object_type', 'pod')
                    self.inventory.set_variable(container_name, 'labels', pod_labels)
                    self.inventory.set_variable(container_name, 'annotations', pod_annotations)
                    self.inventory.set_variable(container_name, 'cluster_name', pod.metadata.clusterName)
                    self.inventory.set_variable(container_name, 'pod_node_name', pod.spec.nodeName)
                    self.inventory.set_variable(container_name, 'pod_name', pod.spec.name)
                    self.inventory.set_variable(container_name, 'pod_host_ip', pod.status.hostIP)
                    self.inventory.set_variable(container_name, 'pod_phase', pod.status.phase)
                    self.inventory.set_variable(container_name, 'pod_ip', pod.status.podIP)
                    self.inventory.set_variable(container_name, 'pod_self_link', pod.metadata.selfLink)
                    self.inventory.set_variable(container_name, 'pod_resource_version', pod.metadata.resourceVersion)
                    self.inventory.set_variable(container_name, 'pod_uid', pod.metadata.uid)
                    self.inventory.set_variable(container_name, 'container_name', container.image)
                    self.inventory.set_variable(container_name, 'container_image', container.image)
                    if container.state.running:
                        self.inventory.set_variable(container_name, 'container_state', 'Running')
                    if container.state.terminated:
                        self.inventory.set_variable(container_name, 'container_state', 'Terminated')
                    if container.state.waiting:
                        self.inventory.set_variable(container_name, 'container_state', 'Waiting')
                    self.inventory.set_variable(container_name, 'container_ready', container.ready)
                    self.inventory.set_variable(container_name, 'ansible_remote_tmp', '/tmp/')
                    self.inventory.set_variable(container_name, 'ansible_connection', self.transport)
                    self.inventory.set_variable(container_name, 'ansible_{0}_pod'.format(self.transport),
                                                pod_name)
                    self.inventory.set_variable(container_name, 'ansible_{0}_container'.format(self.transport),
                                                container.name)
                    self.inventory.set_variable(container_name, 'ansible_{0}_namespace'.format(self.transport),
                                                pod.metadata.namespace)

                    # add hostvars from annotation
                    if pod_variables:
                        for key, value in pod_variables.items():
                            self.inventory.set_variable(container_name, key, value)

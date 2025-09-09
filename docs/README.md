# Moodle Operator

For deploying and managing Moodle instances on Kubernetes. The operator leverages the Ansible Operator SDK for automated provisioning and configuration of the web layer: php-fpm, nginx, cronjob, among other resources. In addition, it handles instantiation and updates.

**Key Technologies:**

* Kubernetes
* Ansible Operator SDK
* Moodle

## Prerequisites

* **Database Instance:** A functional database instance is required for Moodle to store its data. You can leverage existing database solutions like [Postgres-operator](https://krestomatio.com/docs/postgres-operator) or provide connection details directly.
  * **Postgres Operator Integration:** When using Postgres Operator within the same namespace, set the `moodle_postgres_meta_name` variable to the corresponding Postgres CR name for automated credential retrieval.
  * **Direct Database Connection:** Alternatively, provide the following environment variables for manual database configuration:
    * `moodle_config_dbhost`: Database hostname or IP address
    * `moodle_config_dbname`: Database name
    * `moodle_config_dbuser`: Database username
    * `moodle_config_dbpass`: Database password

## Installation

**Important Note:** This Moodle Operator is currently in **Beta** stage. Proceed with caution in production deployments.

1. **Install Operator:**
```bash
# Ensure prerequisites are met
kubectl apply -k https://github.com/krestomatio/moodle-operator/config/default?ref=v0.6.34
```

2. **Configure Moodle Instance:**
- Download and modify [this sample](https://raw.githubusercontent.com/krestomatio/moodle-operator/v0.6.34/config/samples/m4e_v1alpha1_moodle.yaml) file to reflect your specific database connection details and any additional configuration options. This file defines the desired state for your Moodle instance.
```bash
curl -sSL 'https://raw.githubusercontent.com/krestomatio/moodle-operator/v0.6.34/config/samples/m4e_v1alpha1_moodle.yaml' -o m4e_v1alpha1_moodle.yaml
# modify m4e_v1alpha1_moodle.yaml
```

3. **Deploy Moodle:**
- Deploy a Moodle instance using the modified configuration:
```bash
kubectl apply -f m4e_v1alpha1_moodle.yaml
```

4. **Monitor Logs:**
- Track the Moodle Operator logs for insights into the deployment process:
```bash
kubectl -n moodle-operator-system logs -l control-plane=controller-manager -c manager -f
```

- Monitor the status of your deployed Moodle instance:
```bash
kubectl get -f m4e_v1alpha1_moodle.yaml -w
```

**Moodle Admin Password Reset:**

To reset the admin password, provide a new BCrypt-compatible hash in the `moodle_new_adminpass_hash` field of the Moodle CR. You can generate a hash using tools like Python:
```bash
admin_pass=changeme
python -c "import bcrypt; print(bcrypt.hashpw(b'$admin_pass', bcrypt.gensalt(rounds=10)).decode('ascii'))"
```

## Uninstall

1. **Delete Moodle Instance:**
```bash
# Caution: This step leads to data loss. Proceed with caution.
kubectl delete -f m4e_v1alpha1_moodle.yaml
```

2. **Uninstall Operator:**
```bash
kubectl delete -k https://github.com/krestomatio/moodle-operator/config/default?ref=v0.6.34
```

## Configuration
Moodle custom resource (CR) can be configure via its spec field. Moodle CR spec supports all the the variables in [v1alpha1.m4e.moodle ansible role](https://krestomatio.com/docs/ansible-collection-k8s/roles/v1alpha1.m4e.moodle/defaults/main/moodle) as fields. These variables can be specified directly in the Moodle CR YAML manifest file, allowing for customization of the Moodle instance during deployment. Refer to the official [v1alpha1.m4e.moodle ansible role documentation](https://krestomatio.com/docs/ansible-collection-k8s/roles/v1alpha1.m4e.moodle/) for a comprehensive list of supported fields.

## Customizing the Moodle Image

The project utilizes an immutable image approach for Moodle deployments. If you require image customization, refer to the guide on building and customizing the image: [Custom Moodle Image Builds](https://krestomatio.com/docs/container_builder/moodle/#custom-builds)

## Contributing

* Report bugs, request enhancements, or propose new features using GitHub issues.

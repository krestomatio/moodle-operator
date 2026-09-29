# Repository guidance

Before working, read these optional instruction files in order,
resolving these paths from this repository's root:

1. `.agents/organization/AGENTS.md`
2. `.agents/workspace/AGENTS.md`

Read each file if it resolves to a readable regular file.
Skip absent files; report broken or unreadable links.
Read each resolved file only once to avoid duplicate loading and cycles.

Resolve references inside imported files relative to their real target
directory after following symlinks.

Apply organization guidance, then workspace guidance, then the repository
instructions below. More specific applicable instructions take precedence.

Follow this repository's documentation and any more specific instructions for
the files being changed.

## Repository scope

- This Ansible Operator SDK project reconciles Moodle custom resources for the
  LMS meta-operator, including application configuration, workloads, storage,
  services, routes/ingress, jobs, lifecycle state, and status.
- `watches.yaml`, `playbooks/`, `config/crd/`, samples, bundle metadata, and the
  pinned `krestomatio.k8s` collection define its public behavior.
- Preserve the existing CRD identity, spec/status schema, labels, storage and
  suspend/delete semantics. Coordinate image/config changes with
  `container_builder`, the LMS meta-operator, and deployment templates.

## Validation

- Initialize `hack/mk` and `molecule`, then run `make ansible-lint` and
  `make molecule`. When CRDs, RBAC, samples, or release metadata change, run the
  appropriate generation and `make bundle`, reviewing generated diffs.
- Use disposable clusters for integration tests. Deployment, image push, bundle
  publication, and release targets need separate authorization.

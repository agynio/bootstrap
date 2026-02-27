# Platform stack

Deploy platform workloads via Argo CD applications that reference the Helm charts in [agynio/platform](https://github.com/agynio/platform).

## Prerequisites

- `stacks/k8s` and `stacks/system` applied so that Argo CD is installed in the cluster.
- Argo CD authentication token with permissions to manage applications.

## Usage

```bash
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Argo CD details
terraform init
terraform validate
terraform apply
```

For local clusters, Argo CD is typically reached via port-forwarding:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Use the forwarded address (`http://localhost:8080`) along with an Argo CD token in `terraform.tfvars` when running this stack.

# Assumptions

* verison of k8s probably not important -  it's set to 1.19, but we can upgrade to 1.21 when stable
* public repo for docker image also probably not the most important thing/I don't want to pay money for this interview

To grab cluster kubeconfig:
``` sh
aws eks --region eu-central-1 update-kubeconfig --name terraform-EKScluster-reaqta-interview
```

# Terraform guidance
This really needs to be automated via ci/cd, but currently, if you wanna apply this config, you gotta have local aws credentials configured in your `.aws` directory and then you gotta do a `terraform init && terraform apply`

Required Terraform verison is at least .15 or so, but I deployed this all using v1.0.9.

Tip: if you don't have it already, install tfenv (`brew install tfenv`) to manage terraform versions

## Nice to have TODO
Set up proper terraform workspaces and change environments to be dev/prod with variables as well

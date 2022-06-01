# Configuration
## Prerequisites

- terraform
- awscli 
- kubectl
- helm 
- linux - this manifest wouldn't work on windows machine because of broken archive provider

## AWS config

To configure aws environment create file ~\.aws\credentials 
```
[default]
aws_access_key_id = ...
aws_secret_access_key = ...
```
# Usage
## Terraform 
- terraform init to initialize modules and resources
- terraform apply to rollout the cluster

## TC startup
### Login into TC 
- use link from external_address output
### Get super user token
- update kubeconfig via command from sync_cluster_config output
- get token string with kubectl commad from get_main_deployment_logs output

### Finish initialization
- With user token login into TC webserver and click proceed
- Choose server main
- Create admin user
- Secondary server nodes will be added automatically after server initialization will bw finished
- Authorize agents from menu
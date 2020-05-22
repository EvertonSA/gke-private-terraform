# gke-private-terraform

## Requirements
To apply these changes you must use Google Cloud Shell and has to be Owner of the GCP project. 

### How to access bastion server:
`gcloud beta compute ssh --zone "southamerica-east1-a" "private-cluster-bastion" --project "$project_name"`

### How to provisioning the cluster:

please review variables.tf before applying terraform files to GCP!

```
# on root path, 
./init.sh

# on dev folder
terraform init
terraform apply -auto-approve
```

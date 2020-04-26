# gke-private-terraform

how to access bastion server:
1 - gcloud beta compute ssh --zone "southamerica-east1-a" "private-cluster-bastion" --project "$project_name"

how to provisioning the cluster:
1 - terraform init
2 - terraform apply -auto-approve
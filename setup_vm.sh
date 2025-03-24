#!/bin/bash
exec > /var/log/startup.log 2>&1

set -e
set -x

sudo apt update
sudo apt install -y apt-transport-https ca-certificates gnupg curl
sudo apt install -y python3.10-venv

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update
sudo apt install -y kubectl
sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin

export HOME=/home/ubuntu
gcloud container clusters get-credentials "${google_container_cluster.default.name}" --region "${google_container_cluster.default.location}" --project "${var.project_id}"
kubectl config rename-context gke_"${var.project_id}"_"${google_container_cluster.default.location}"_"${google_container_cluster.default.name}" gke-cluster
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
sudo chown -R ubuntu:ubuntu /home/ubuntu/.config
echo "GKE access configured on this VM!"

sudo snap install charmcraft --classic
sudo snap install terraform --classic

sudo snap install juju
mkdir -p ~/.local/share/juju
sudo snap install yq jhack

/snap/juju/current/bin/juju  add-k8s --cloud gke-cluster k8s --client

mkdir -p /home/ubuntu/.local/share/juju
sudo chown -R ubuntu:ubuntu /home/ubuntu/.local

sudo -u ubuntu juju bootstrap k8s --debug
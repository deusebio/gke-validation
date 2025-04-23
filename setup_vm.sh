#!/bin/bash
exec > /var/log/startup.log 2>&1

set -e
set -x

sudo apt update
sudo apt install -y apt-transport-https ca-certificates gnupg curl
sudo apt install -y python3.10-venv
sudo apt install -y python3-pip

echo "PATH=$PATH:/home/ubuntu/.local/bin" >> /home/ubuntu/.bashrc
pip install poetry

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update
sudo apt install -y kubectl
sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin

export HOME=/home/ubuntu
gcloud container clusters get-credentials ${cluster_name} --region ${cluster_region} --project ${project_id}
kubectl config rename-context gke_${project_id}_${cluster_region}_${cluster_name} gke-cluster
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
sudo chown -R ubuntu:ubuntu /home/ubuntu/.config
echo "GKE access configured on this VM!"

sudo snap install charmcraft --classic
sudo snap install terraform --classic
sudo snap install emacs --classic

sudo snap install juju
mkdir -p ~/.local/share/juju
sudo snap install yq jhack

/snap/juju/current/bin/juju  add-k8s --cloud gke-cluster k8s --client

/snap/juju/current/bin/juju bootstrap k8s gke-controller --debug --config controller-service-type=loadbalancer
mkdir -p /home/ubuntu/.local/share/juju
sudo chown -R ubuntu:ubuntu /home/ubuntu/.local

# /snap/juju/current/bin/juju bootstrap k8s gke-controller --debug --config controller-service-type=loadbalancer
echo "Juju controller bootstrapped"

JUJU_CMD="sudo -u ubuntu juju"

$JUJU_CMD add-model kubeflow

$JUJU_CMD deploy kubeflow --trust --channel=1.10/stable
$JUJU_CMD deploy mlflow --channel=2.15/stable --trust
$JUJU_CMD deploy resource-dispatcher --channel 2.0/stable --trust

echo "KF deployed"

$JUJU_CMD config dex-auth static-username=admin
$JUJU_CMD config dex-auth static-password=admin

$JUJU_CMD integrate mlflow-server:secrets resource-dispatcher:secrets
$JUJU_CMD integrate mlflow-server:pod-defaults resource-dispatcher:pod-defaults
$JUJU_CMD integrate mlflow-minio:object-storage kserve-controller:object-storage
$JUJU_CMD integrate kserve-controller:service-accounts resource-dispatcher:service-accounts
$JUJU_CMD integrate kserve-controller:secrets resource-dispatcher:secrets

echo "KF configured"

cd /home/ubuntu
sudo -u ubuntu git clone https://github.com/canonical/charmed-kubeflow-uats.git -b track/1.10

cd charmed-kubeflow-uats
sudo -u ubuntu poetry update lightkube --lock
sudo -u ubuntu python3.10 -m venv uats
source uats/bin/activate

sudo chown -R ubuntu:ubuntu /home/ubuntu/charmed-kubeflow-uats/uats
sudo chown -R ubuntu:ubuntu /home/ubuntu/.cache
sudo -u ubuntu pip install tox

sudo -u ubuntu juju wait-for model kubeflow --query='forEach(units, unit => unit.agent-status=="idle" && unit.workload-status=="active")' --timeout 30m0s

sudo -u ubuntu /home/ubuntu/.local/bin/tox -e uats-remote >uats.out 2>uats.err

echo "Done!"

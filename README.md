# Terraform setup for Charmed Kubeflow on GKE

The following repository provides the artifacts for deploying a GKE cluster with Kubeflow on top of it, and running Kubeflow UATs.

It requires a terraform provider to be available, that can be installed with

```
sudo snap install terraform 
```

# Basic Usage

Install Terraform

```
sudo snap install terraform --classic
```

Set up Google credentials:

```
sudo snap install google-cloud-cli --classic
gcloud auth login
```

Apply the terraform module

```
terraform init
terraform apply -auto-approve
```

> [!NOTE]  
> The TF module has the project-id as an input. Make sure to provide the project id for which you have sufficient permission to create and manage relevant resources required in the TF modules.

The output of the terraform module is the IP for the jump host that you can connect to where the bootstrapping process as well as the UATs are running.

## Known issues

Sometimes the init script `setup_vm.sh` is hanging or failing because of `cgroup` missing permissions. This is generally not happening when you can login to the machine straight away and tail the output for the `setup_vm.sh` script at `/var/log/startup.log` file.

For the UATs to pass, it is also critical that the sysctl properties of the worker K8s nodes are setup correctly. The `set_sysctl.sh` script provides the commands how you can set this up manually. Run the script, take the output and run it in a shell.
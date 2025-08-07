#!/bin/bash

set -e

echo "[Step 1] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[Step 2] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[Step 3] Configuring kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "[Step 4] Setting up sysctl params..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

echo "[Step 5] Installing containerd..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

#Configuring the systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd


echo "[Step 6] Installing kubeadm, kubelet, and kubectl..."
#1. Add Google Cloud’s GPG key
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#2. Add Kubernetes APT repository
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list


#3. Update and Install
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#4 (Optional) Enable the kubelet service before running kubeadm:
sudo systemctl enable --now kubelet

#4. Verify Installation
kubeadm version
kubectl version --client
kubelet --version

# Enable and start kubelet service
systemctl daemon-reload 
systemctl start kubelet 
systemctl enable kubelet.service


#===================
#Steps 7, 8 & 9 should be executed in Master Node.


echo "[Step 7] Initialize Kubernetes Cluster with Kubeadm (master node)"
sudo kubeadm init

#exit from root user to run below commands.
#exit


#run below commands as regular user in master node only.
echo "[Step 8] Configuring kubeconfig for user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[Step 9] Installing WeaveNet CNI..."
#Weave Net CNI can now be installed on a kubernetes cluster using
KUBEVER=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f https://reweave.azurewebsites.net/k8s/net?k8s-version=$KUBEVER



# To verify, if kubectl is working or not, run the following command.
kubectl get pods -o wide -n kube-system


# Get joining token from master node.
sudo kubeadm token create --print-join-command

#===================

echo "[Step 10] Kubernetes installation completed!"
kubectl get nodes

echo "[step 11] versions check"
kubeadm version
kubectl version --client
kubelet --version

#Add Worker Machines to Kubernates Master
#=========================================

#Copy kubeadm join token from and execute in Worker Nodes to join to cluster


#kubectl commonds has to be executed in master machine.

#Check Nodes 
#=============

#kubectl get nodes

#To label worker nodes as Worker, execute these in master node.
#kubectl label node ip-172-31-37-161 node-role.kubernetes.io/worker=
#kubectl label node ip-172-31-46-189 node-role.kubernetes.io/worker=

#Deploy Sample Application
#==========================

#kubectl run nginx-demo --image=nginx --port=80 

#kubectl expose pod nginx-demo --port=80 --type=NodePort


#Get Node Port details 
#=====================
#kubectl get services	
{\rtf1\ansi\ansicpg1252\cocoartf2820
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/bin/bash\
\
set -e\
\
echo "[Step 1] Updating system..."\
sudo apt update && sudo apt upgrade -y\
\
echo "[Step 2] Disabling swap..."\
sudo swapoff -a\
sudo sed -i '/ swap / s/^/#/' /etc/fstab\
\
echo "[Step 3] Configuring kernel modules..."\
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf\
overlay\
br_netfilter\
EOF\
\
sudo modprobe overlay\
sudo modprobe br_netfilter\
\
echo "[Step 4] Setting up sysctl params..."\
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf\
net.bridge.bridge-nf-call-ip6tables = 1\
net.bridge.bridge-nf-call-iptables = 1\
net.ipv4.ip_forward = 1\
EOF\
sudo sysctl --system\
\
echo "[Step 5] Installing containerd..."\
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release\
sudo mkdir -p /etc/apt/keyrings\
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg\
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list\
sudo apt update\
sudo apt install -y containerd.io\
sudo mkdir -p /etc/containerd\
containerd config default | sudo tee /etc/containerd/config.toml\
sudo systemctl restart containerd\
sudo systemctl enable containerd\
\
echo "[Step 6] Installing kubeadm, kubelet, and kubectl..."\
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -\
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list\
sudo apt update\
sudo apt install -y kubelet kubeadm kubectl\
sudo apt-mark hold kubelet kubeadm kubectl\
\
echo "[Step 7] Initializing Kubernetes cluster..."\
sudo kubeadm init --pod-network-cidr=10.244.0.0/16\
\
echo "[Step 8] Configuring kubeconfig for user..."\
mkdir -p $HOME/.kube\
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config\
sudo chown $(id -u):$(id -g) $HOME/.kube/config\
\
echo "[Step 9] Installing Flannel CNI..."\
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml\
\
echo "[Step 10] Allow scheduling pods on master (single-node setup)..."\
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true\
\
echo "[Step 11] Kubernetes installation completed!"\
kubectl get nodes\
}
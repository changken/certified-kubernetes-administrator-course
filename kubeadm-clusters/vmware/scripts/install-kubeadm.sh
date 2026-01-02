#!/bin/bash
#
# Install kubeadm, kubelet, and kubectl
#
# This script installs Kubernetes components.
# Run this on ALL nodes AFTER running k8s-prerequisites.sh.
#
# Usage:
#   chmod +x install-kubeadm.sh
#   sudo ./install-kubeadm.sh
#

set -e

# Kubernetes version (change as needed)
KUBE_VERSION="1.35"

echo "=========================================="
echo "Installing Kubernetes ${KUBE_VERSION}"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

echo ""
echo "[1/4] Installing dependencies..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

echo ""
echo "[2/4] Adding Kubernetes apt repository..."
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

echo ""
echo "[3/4] Installing kubeadm, kubelet, kubectl..."
apt-get update
apt-get install -y kubelet kubeadm kubectl

echo ""
echo "[4/4] Holding packages at current version..."
apt-mark hold kubelet kubeadm kubectl

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Installed versions:"
kubeadm version -o short
kubelet --version
kubectl version --client -o yaml | grep gitVersion

echo ""
echo "Next steps:"
echo "  On controlplane:"
echo "    kubeadm init --apiserver-advertise-address=<IP> --pod-network-cidr=10.244.0.0/16"
echo ""
echo "  On workers:"
echo "    kubeadm join <controlplane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
echo ""

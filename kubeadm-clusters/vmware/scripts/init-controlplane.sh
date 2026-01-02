#!/bin/bash
#
# Initialize Kubernetes Control Plane
#
# This script initializes the Kubernetes control plane using kubeadm.
# Run this ONLY on the controlplane node.
#
# Usage:
#   chmod +x init-controlplane.sh
#   sudo ./init-controlplane.sh
#

set -e

echo "=========================================="
echo "Initializing Kubernetes Control Plane"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the primary IP address
PRIMARY_IP=$(ip route | grep default | awk '{ print $9 }' | head -1)

if [ -z "$PRIMARY_IP" ]; then
    echo "Error: Could not detect primary IP address"
    echo "Please run manually with:"
    echo "  kubeadm init --apiserver-advertise-address=<YOUR_IP> --pod-network-cidr=10.244.0.0/16"
    exit 1
fi

echo ""
echo "Detected primary IP: $PRIMARY_IP"
echo ""

# Pod network CIDR (for Flannel)
POD_CIDR="10.244.0.0/16"

echo "Configuration:"
echo "  API Server Address: $PRIMARY_IP"
echo "  Pod Network CIDR:   $POD_CIDR"
echo ""

read -p "Continue with initialization? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "[1/4] Running kubeadm init..."
kubeadm init \
    --apiserver-advertise-address=$PRIMARY_IP \
    --pod-network-cidr=$POD_CIDR \
    --upload-certs

echo ""
echo "[2/4] Setting up kubectl for vagrant user..."
VAGRANT_HOME="/home/vagrant"
mkdir -p $VAGRANT_HOME/.kube
cp -i /etc/kubernetes/admin.conf $VAGRANT_HOME/.kube/config
chown -R vagrant:vagrant $VAGRANT_HOME/.kube

echo ""
echo "[3/4] Installing Flannel CNI..."
sudo -u vagrant kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo ""
echo "[4/4] Waiting for nodes to be ready..."
sleep 10

echo ""
echo "=========================================="
echo "Control Plane Initialization Complete!"
echo "=========================================="
echo ""
echo "Node status:"
sudo -u vagrant kubectl get nodes

echo ""
echo "Pod status:"
sudo -u vagrant kubectl get pods -A

echo ""
echo "=========================================="
echo "To join worker nodes, run the following on each worker:"
echo "=========================================="
echo ""
kubeadm token create --print-join-command
echo ""

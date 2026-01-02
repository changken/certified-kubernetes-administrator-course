#!/bin/bash
#
# Kubernetes Prerequisites Setup Script
#
# This script configures all prerequisites for installing Kubernetes with kubeadm.
# Run this on ALL nodes (controlplane, node01, node02) BEFORE running kubeadm.
#
# Usage:
#   chmod +x k8s-prerequisites.sh
#   sudo ./k8s-prerequisites.sh
#

set -e

echo "=========================================="
echo "Kubernetes Prerequisites Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

echo ""
echo "[1/6] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
echo "     Swap disabled."

echo ""
echo "[2/6] Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
echo "     Kernel modules loaded."

echo ""
echo "[3/6] Configuring sysctl parameters..."
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null 2>&1
echo "     Sysctl parameters configured."

echo ""
echo "[4/6] Installing containerd..."
if ! command -v containerd &> /dev/null; then
    apt-get update
    apt-get install -y containerd
fi
echo "     containerd installed."

echo ""
echo "[5/6] Configuring containerd..."
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Enable SystemdCgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Update sandbox image (optional, fixes warning)
sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.10.1"|' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd
echo "     containerd configured."

echo ""
echo "[6/6] Installing CNI plugins..."
CNI_VERSION="v1.3.0"
if [ ! -f /opt/cni/bin/bridge ]; then
    mkdir -p /opt/cni/bin
    curl -sL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
fi
echo "     CNI plugins installed."

echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

echo ""
echo "Swap status:"
free -h | grep Swap

echo ""
echo "IP forwarding:"
cat /proc/sys/net/ipv4/ip_forward

echo ""
echo "Bridge netfilter:"
cat /proc/sys/net/bridge/bridge-nf-call-iptables

echo ""
echo "Kernel modules:"
lsmod | grep -E "br_netfilter|overlay" | awk '{print $1}'

echo ""
echo "containerd status:"
systemctl is-active containerd

echo ""
echo "CNI plugins:"
ls /opt/cni/bin/ | head -5
echo "..."

echo ""
echo "=========================================="
echo "Prerequisites setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Install kubeadm, kubelet, kubectl"
echo "  2. On controlplane: kubeadm init"
echo "  3. On workers: kubeadm join"
echo ""

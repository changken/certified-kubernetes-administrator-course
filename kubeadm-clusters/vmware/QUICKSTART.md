# VMware Kubernetes Cluster - Quick Start Guide

This guide will help you quickly set up a Kubernetes cluster using VMware Workstation/Fusion and Vagrant.

## Prerequisites Checklist

- [ ] VMware Workstation Pro/Player (Windows/Linux) or VMware Fusion (macOS)
- [ ] Vagrant 2.3.0 or later
- [ ] At least 6GB available RAM
- [ ] 20GB free disk space

## Step 1: Install Vagrant VMware Plugin

Open a terminal (PowerShell on Windows) and run:

```bash
vagrant plugin install vagrant-vmware-desktop
```

Verify the installation:

```bash
vagrant plugin list
```

You should see `vagrant-vmware-desktop` in the output.

## Step 2: Clone the Repository

```bash
git clone https://github.com/kodekloudhub/certified-kubernetes-administrator-course.git
cd certified-kubernetes-administrator-course/kubeadm-clusters/vmware
```

## Step 3: Configure Network Mode (Optional)

The default mode is **BRIDGE**, which places VMs on your local network.

To use **NAT** mode instead, edit the `Vagrantfile`:

```ruby
BUILD_MODE = "NAT"  # Change from "BRIDGE" to "NAT"
```

### When to use NAT mode:
- Limited network IP addresses available
- BRIDGE mode doesn't work with your network setup
- You don't need external browser access to NodePort services

## Step 4: Start the Cluster

```bash
vagrant up
```

This will:
1. Download the bento/ubuntu-22.04 box (first time only, ~500MB)
2. Create 3 VMs: 1 control plane + 2 worker nodes
3. Configure networking
4. Set up SSH access

**Expected time:** 10-20 minutes (depending on your internet speed for the first run)

## Step 5: Access the Control Plane

```bash
vagrant ssh controlplane
```

You are now logged into the control plane node!

## Step 6: Set Up SSH Between Nodes (Optional but Recommended)

From the `controlplane` node:

```bash
# Generate SSH key
ssh-keygen

# Press ENTER to accept all defaults

# Copy key to worker nodes (password: vagrant)
ssh-copy-id -o StrictHostKeyChecking=no vagrant@node01
ssh-copy-id -o StrictHostKeyChecking=no vagrant@node02
```

## Step 7: Install Kubernetes

Follow the detailed instructions starting from [Node Setup](../../generic/04-node-setup.md).

Or continue with the official documentation at [docs/01-prerequisites.md](./docs/01-prerequisites.md).

## Common Commands

```bash
# Check VM status
vagrant status

# SSH into a specific VM
vagrant ssh controlplane
vagrant ssh node01
vagrant ssh node02

# Stop all VMs (saves state)
vagrant halt

# Start all VMs
vagrant up

# Restart all VMs
vagrant reload

# Destroy all VMs
vagrant destroy -f

# Destroy a specific VM
vagrant destroy node01 -f
```

## Troubleshooting

### Issue: Plugin not found
**Solution:**
```bash
vagrant plugin install vagrant-vmware-desktop
```

### Issue: VMs not getting IP addresses in BRIDGE mode
**Solution:** Switch to NAT mode by editing `Vagrantfile`:
```ruby
BUILD_MODE = "NAT"
```

### Issue: Not enough memory
**Solution:** Edit `Vagrantfile` and reduce memory:
- Control plane: `vmware.vmx["memsize"] = "1024"` (line ~128)
- Workers: `vmware.vmx["memsize"] = "512"` (line ~155)

### Issue: VMware GUI windows are annoying
**Solution:** Disable GUI in `Vagrantfile`:
```ruby
vmware.gui = false
```

### Issue: Vagrant stuck during provisioning
**Solution:**
1. Press `CTRL+C`
2. Kill any Ruby processes
3. Destroy the stuck VM: `vagrant destroy <vm-name>`
4. Re-run: `vagrant up`

## Network Configuration

### BRIDGE Mode (Default)
- VMs get IPs from your router's DHCP
- Access NodePort services from your browser
- Example: `http://<worker-ip>:30000`

### NAT Mode
- VMs use private network: `192.168.56.0/24`
- Control plane: `192.168.56.11`
- Worker 1: `192.168.56.21`
- Worker 2: `192.168.56.22`
- SSH port forwarding enabled:
  - Control plane: `localhost:2710`
  - Worker 1: `localhost:2721`
  - Worker 2: `localhost:2722`

## Default VM Resources

| Node | CPUs | RAM | IP (NAT Mode) |
|------|------|-----|---------------|
| controlplane | 2 | 2GB | 192.168.56.11 |
| node01 | 1 | 1GB | 192.168.56.21 |
| node02 | 1 | 1GB | 192.168.56.22 |

## Next Steps

After VMs are running:

1. Follow the [Connectivity Guide](./docs/03-connectivity.md)
2. Continue with [Node Setup](../../generic/04-node-setup.md)
3. Install Kubernetes components
4. Set up the cluster with kubeadm

## Getting Help

- For VMware-specific issues: Check [docs/02-compute-resources.md](./docs/02-compute-resources.md)
- For Kubernetes setup: Follow the generic guides in `../../generic/`
- Report bugs: [GitHub Issues](https://github.com/kodekloudhub/certified-kubernetes-administrator-course/issues)

## Cleanup

When finished with the cluster:

```bash
# Exit from all VM sessions first
exit

# Destroy all VMs and reclaim disk space
vagrant destroy -f
```

---

**Happy Learning! 🚀**

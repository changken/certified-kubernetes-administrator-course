# Installing Kubernetes the kubeadm way on VMware Workstation

Updated December 2024

This guide provides instructions for setting up a Kubernetes cluster using kubeadm on VMware Workstation/Fusion.

## Compatibility

This configuration has been tested with:
- VMware Workstation 17.x and later (including 25H2)
- VMware Fusion 13.x and later
- Ubuntu 22.04 LTS (Jammy Jellyfish) via bento/ubuntu-22.04 box
- Kubernetes 1.28+

## Prerequisites

Before you begin, ensure you have:
1. VMware Workstation Pro/Player (Windows/Linux) or VMware Fusion (macOS)
2. Vagrant 2.3.0 or later
3. Vagrant VMware Desktop plugin
4. At least 6GB of available RAM
5. 20GB of free disk space

## Quick Start

1. Install the Vagrant VMware Desktop plugin:
   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```

2. Clone this repository and navigate to the VMware directory:
   ```bash
   cd kubeadm-clusters/vmware
   ```

3. Start the cluster:
   ```bash
   vagrant up
   ```

4. SSH into the control plane:
   ```bash
   vagrant ssh controlplane
   ```

## Network Modes

This Vagrantfile supports two network modes:

### BRIDGE Mode (Default)
- VMs are placed on your local network
- Each VM gets an IP from your DHCP server
- Cluster is accessible from your browser
- Requires sufficient spare IPs on your network

### NAT Mode
- VMs are in a private virtual network (192.168.56.0/24)
- Cluster requires port forwarding for external access
- Use this if BRIDGE mode doesn't work for you

To switch to NAT mode, edit the `Vagrantfile` and change:
```ruby
BUILD_MODE = "NAT"
```

## Cluster Configuration

Default configuration:
- **Control Plane**: 2 CPU, 2GB RAM
- **Worker Nodes**: 1 CPU, 1GB RAM each
- **Number of Workers**: 2 (configurable via `NUM_WORKER_NODES`)

## Detailed Documentation

- [Prerequisites and Setup](./docs/01-prerequisites.md) - Detailed step-by-step instructions
- [Box Selection Guide](./BOX_SELECTION.md) - Why we use bento/ubuntu-22.04 instead of ubuntu/jammy64

## Common Commands

```bash
# Start all VMs
vagrant up

# Start a specific VM
vagrant up controlplane
vagrant up node01

# SSH into a VM
vagrant ssh controlplane
vagrant ssh node01

# Check status
vagrant status

# Stop all VMs
vagrant halt

# Destroy all VMs
vagrant destroy -f

# Reload configuration
vagrant reload
```

## Troubleshooting

### Box Provider Errors

If you see an error like "The box you're attempting to add doesn't support the provider", this means the box doesn't have a VMware version available. The Vagrantfile uses `bento/ubuntu-22.04` which supports VMware.

**For detailed explanation, see [BOX_SELECTION.md](./BOX_SELECTION.md)**

If you want to use a different box, search for boxes at [Vagrant Cloud](https://app.vagrantup.com/boxes/search) and filter by "vmware_desktop" provider.

### VMware GUI Option
If you want to disable the GUI for VMs, edit the Vagrantfile and change:
```ruby
vmware.gui = false
```

### Network Issues
If you encounter network connectivity issues in BRIDGE mode:
1. Verify your network adapter is correctly detected
2. Try switching to NAT mode
3. Check VMware network settings

### Plugin Issues
If the VMware plugin isn't working:
```bash
# Reinstall the plugin
vagrant plugin uninstall vagrant-vmware-desktop
vagrant plugin install vagrant-vmware-desktop
```

## Differences from VirtualBox Version

- Uses `vmware_desktop` provider instead of `virtualbox`
- VMware-specific configuration syntax (`vmware.vmx`)
- GUI is enabled by default for easier VM management
- Machine IDs stored in `.vagrant/machines/*/vmware_desktop/`

## Additional Resources

- [Vagrant VMware Provider Documentation](https://www.vagrantup.com/docs/providers/vmware)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)

## License

This project follows the same license as the main repository.

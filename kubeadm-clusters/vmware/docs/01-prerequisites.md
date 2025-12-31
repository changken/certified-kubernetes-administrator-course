# Prerequisites

## VM Hardware Requirements

* 8 GB of RAM (16 preferred)
* 8-core/4-core hyperthreaded or better CPU, e.g. Core-i7/Core-i9 (will be slow otherwise)
* 50 GB Disk space

## git

Required to download the repo. It is normally pre-installed on Mac, but not on Windows. If you need to install it, see [here](https://git-scm.com/download).

## VMware Workstation/Fusion

Download and Install VMware on your platform:

### Windows and Linux
- **VMware Workstation Pro** 17.x or later (including 25H2)
- **VMware Workstation Player** (Free for personal use)
- Download from [VMware Downloads](https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html)

### macOS
- **VMware Fusion** 13.x or later
- **VMware Fusion Player** (Free for personal use)
- Download from [VMware Fusion Downloads](https://www.vmware.com/products/fusion.html)

This lab was last tested with VMware Workstation 17.5.x and 25H2, though newer versions should be ok.

**Note:** VMware Workstation Player and VMware Fusion Player are free for personal, non-commercial use.

## Vagrant

Once VMware is installed you may choose to deploy virtual machines manually on it.
Vagrant provides an easier way to deploy multiple virtual machines on VMware more consistently.

Download and Install [Vagrant](https://www.vagrantup.com/) on your platform.

This lab was last tested with Vagrant 2.3.7 and 2.4.x, though newer versions should be ok.

## Vagrant VMware Desktop Plugin

**IMPORTANT:** You must install the Vagrant VMware Desktop plugin to use Vagrant with VMware.

### Installation

```bash
vagrant plugin install vagrant-vmware-desktop
```

### Verification

Verify the plugin is installed:

```bash
vagrant plugin list
```

You should see `vagrant-vmware-desktop` in the output.

### Licensing (Optional)

- The Vagrant VMware Desktop plugin is **free** to use with VMware Workstation Player and VMware Fusion Player
- If using VMware Workstation Pro or VMware Fusion Pro, the plugin is still free as of recent versions
- Check [Vagrant VMware Provider](https://www.vagrantup.com/docs/providers/vmware) for the latest licensing information

## Lab Defaults

The labs have been configured with the following networking defaults. If you change any of these after you have deployed any of the lab, you'll need to completely reset it and start again from the beginning:

```bash
vagrant destroy -f
vagrant up
```

If you do change any of these, **please consider that a personal preference and don't submit a PR for it**.

### Virtual Machine Network

Due to how VMware/Vagrant works, the networking for each VM uses VMware's network adapters. By default, Kubernetes components will connect to the default network adapter, therefore we have pre-set an environment variable `PRIMARY_IP` on all VMs which is the IP address that Kubernetes components should be using. In the coming labs you will see this environment variable being used to ensure Kubernetes components bind to the correct network interface.

`PRIMARY_IP` is defined as the IP address of the network interface on the node that is connected to the network having the default gateway, and is the interface that a node will use to talk to the other nodes. For those interested, this variable is assigned the result of the following command

```bash
ip route | grep default | awk '{ print $9 }'
```

#### Bridge Networking

The default configuration in this lab is to bring the VMs up on bridged interfaces. What this means is that your Kubernetes nodes will appear as additional machines on your local network, their IP addresses being provided dynamically by your broadband router. This facilitates the use of your browser to connect to any NodePort services you deploy.

Should you have issues deploying bridge networking, please raise a [bug report](https://github.com/kodekloudhub/certified-kubernetes-administrator-course/issues) and include all details including the output of `vagrant up`.

Then retry the lab in NAT mode. How to do this is covered in the [next section](./02-compute-resources.md).

#### NAT Networking

In NAT configuration, the network on which the VMs run is isolated from your broadband router's network by a NAT gateway managed by VMware. This means that VMs can see out (and connect to Internet), but you can't see in (i.e. use browser to connect to NodePorts) without setting up individual port forwarding rules for every NodePort using the VMware UI.

The network used by the VMware virtual machines is `192.168.56.0/24`.

To change this, edit the [Vagrantfile](../Vagrantfile) in your cloned copy (do not edit directly in github), and set the new value for the network prefix at line 16. This should not overlap any of the other network settings.

Note that you do not need to edit any of the other scripts to make the above change. It is all managed by shell variable computations based on the assigned VM IP addresses and the values in the hosts file (also computed).

It is *recommended* that you leave the pod and service networks as the defaults. If you change them then you will also need to edit the Weave networking manifests to accommodate your change.

If you do decide to change any of these, please treat as personal preference and do not raise a pull request.

### Pod Network

The network used to assign IP addresses to pods is `10.244.0.0/16`.

To change this, open all the `.md` files in the [docs](../docs/) directory in your favourite IDE and do a global replace on<br>
`POD_CIDR=10.244.0.0/16`<br>
with the new CIDR range. This should not overlap any of the other network settings.

### Service Network

The network used to assign IP addresses to Cluster IP services is `10.96.0.0/16`.

To change this, open all the `.md` files in the [docs](../docs/) directory in your favourite IDE and do a global replace on<br>
`SERVICE_CIDR=10.96.0.0/16`<br>
with the new CIDR range. This should not overlap any of the other network settings.

## Running Commands in Parallel with tmux

If you are running this tutorial on a Mac, you can instead use iterm2 to achieve this. See the iterm2 setup in the [Apple Silicon guide](../../apple-silicon/docs/01-prerequisites.md#running-commands-in-parallel-with-iterm2).

[tmux](https://github.com/tmux/tmux/wiki) can be used to run the same commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances. In those cases you may consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

In order to use tmux, you must first connect to `controlplane` and run tmux there. From inside the tmux session you can open multiple panes and ssh to the worker nodes from these panes.

*The use of tmux is optional and not required to complete this tutorial*.

![tmux screenshot](../../../images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `CTRL+B` followed by `"` to split the window into two panes. In each pane (selectable with mouse), ssh to the host(s) you will be working with.</br>Next type `CTRL+X` at the prompt to begin sync. In sync mode, the dividing line between panes will be red. Everything you type or paste in one pane will be echoed in the other.<br>To disable synchronization type `CTRL+X` again.</br></br>Note that the `CTRL-X` key binding is provided by a `.tmux.conf` loaded onto the VM by the vagrant provisioner.<br/>To paste commands into a tmux pane, use `SHIFT-RightMouseButton`.

## VMware-Specific Notes

### Vagrant Box for VMware

This setup uses the `bento/ubuntu-22.04` box instead of `ubuntu/jammy64` because the official Ubuntu box doesn't support VMware providers. The Bento boxes are well-maintained and support multiple providers including VMware.

### GUI Mode
By default, the Vagrantfile enables GUI mode for VMs, which allows you to see the console in VMware. If you prefer headless mode, edit the Vagrantfile and set:

```ruby
vmware.gui = false
```

### Network Adapter Detection
The Vagrantfile automatically detects your primary network adapter for BRIDGE mode:
- **Windows**: Uses PowerShell to detect the default network adapter
- **Linux**: Uses `ip route` command
- **macOS**: Uses a helper script

If automatic detection fails, you can manually specify the adapter by editing the `get_bridge_adapter()` function in the Vagrantfile.

### VMware Tools
VMware Tools will be automatically installed by Vagrant during VM provisioning. This ensures proper integration between the host and guest systems.

Next: [Compute Resources](02-compute-resources.md)

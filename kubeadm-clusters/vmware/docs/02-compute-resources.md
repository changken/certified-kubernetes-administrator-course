# Provisioning Compute Resources

Note: You must have VMware Workstation/Fusion and Vagrant configured with the VMware Desktop plugin at this point

Open a terminal application (on Windows use PowerShell). All commands in this guide are executed from the terminal.

Download this github repository and cd into the `vmware` folder

```bash
git clone https://github.com/kodekloudhub/certified-kubernetes-administrator-course.git
```

CD into the vmware directory

```bash
cd kubeadm-clusters/vmware
```

Run Vagrant up to create the virtual machines.

```bash
vagrant up
```

## Bridge interface selection

Bridged networking makes the VMs appear as hosts directly on your local network. This means that you will be able to use your own browser to connect to any NodePort services you create in the cluster.

If your workstation has more than one network interface capable of creating a bridge, Vagrant may stop and ask you which one to use if it cannot determine the best interface itself. Now it *should* work this out and not have to ask you, however if it does not, then the "best" interface is the one used to connect to your broadband router. On laptops, this would normally be the Wi-Fi adapter which should be easily identifiable in the list. The example below is from a Windows desktop computer with a wired network adapter.

Which of the two choices do you think is correct?

<details>
<summary>Reveal</summary>

> `Intel(R) Ethernet Connection (2) I219-V`

Why? Because
1. Ethernet is the term often given to wired network connections.
2. The other one is Hyper-V which is internal and used for native running of VMs.

</details>

```text
==> controlplane: Available bridged network interfaces:
1) Intel(R) Ethernet Connection (2) I219-V
2) Hyper-V Virtual Ethernet Adapter
==> controlplane: When choosing an interface, it is usually the one that is
==> controlplane: being used to connect to the internet.
==> controlplane:
    controlplane: Which interface should the network bridge to?
```

At the end of the deployment, it will tell you how to access NodePort services from your browser once you have configured Kubernetes. Make a note of this.

If you encountered issues starting the VMs, you can try NAT mode. Note that in NAT mode you will not be able to connect to your NodePort services using your browser without setting up port forwarding rules in VMware UI.

1. Run
    ```
    vagrant destroy -f
    ```
1. Edit `Vagrantfile` and change `BUILD_MODE = "BRIDGE"` to `BUILD_MODE = "NAT"` at line 10.

## VMware GUI

By default, the VMware GUI is enabled for all VMs, which allows you to see the console window. If you prefer headless operation:

1. Edit the `Vagrantfile`
2. Find the `vmware.gui = true` lines
3. Change them to `vmware.gui = false`

## SSH to the nodes

There are two ways to SSH into the nodes:

### 1. SSH using Vagrant

From the directory you ran the `vagrant up` command, run `vagrant ssh <vm>` for example `vagrant ssh controlplane`.

This is the easiest way as it requires no configuration.

### 2. SSH Using SSH Client Tools

Use your favourite SSH Terminal tool (PuTTY/MobaXTerm etc.).

Use the above IP addresses. Username and password based SSH is disabled by default.
Vagrant generates a private key for each of these VMs. It is placed under the .vagrant folder (in the directory you ran the `vagrant up` command from) at the below path for each VM:

**Private Key Path:** `.vagrant/machines/<machine name>/vmware_desktop/private_key`

**Username/Password:** `vagrant/vagrant`

## Verify Environment

- Ensure all VMs are up
- Ensure VMs are assigned the above IP addresses
- Ensure you can SSH into these VMs using the IP and private keys, or `vagrant ssh`
- Ensure the VMs can ping each other

## Troubleshooting Tips

### Failed Provisioning

If any of the VMs failed to provision, or is not configured correctly, delete the VM using the command:

```bash
vagrant destroy <vm>
```

Then re-provision. Only the missing VMs will be re-provisioned

```bash
vagrant up
```

### VMware Plugin Issues

If you encounter issues with the VMware provider, ensure the plugin is installed:

```bash
vagrant plugin list
```

If `vagrant-vmware-desktop` is not listed, install it:

```bash
vagrant plugin install vagrant-vmware-desktop
```

### Utility Driver Issues (VMware on Windows)

On Windows, if you see errors about the VMware utility driver, you may need to:

1. Install or update VMware Workstation to the latest version
2. Ensure the VMware authorization service is running:
   ```powershell
   Get-Service VMware*
   ```
3. Restart the VMware services if needed

### Network Configuration Issues

If VMs cannot communicate:

1. Check VMware network settings in the VMware UI
2. Verify that VMware's DHCP service is running (for NAT mode)
3. Try switching between BRIDGE and NAT modes
4. Check Windows Firewall or other firewall software

### Provisioner gets stuck

This will most likely happen at "Waiting for machine to reboot"

1. Hit `CTRL+C`
2. Kill any running `ruby` process, or Vagrant will complain.
3. Destroy the VM that got stuck: `vagrant destroy <vm>`
4. Re-provision. It will pick up where it left off: `vagrant up`

# Pausing the Environment

You do not need to complete the entire lab in one session. You may shut down and resume the environment as follows, if you need to power off your computer.

To shut down. This will gracefully shut down all the VMs in the reverse order to which they were started:

```
vagrant halt
```

To power on again:

```
vagrant up
```

# Deleting the Virtual Machines

When you have finished with your cluster and want to reclaim the resources, perform the following steps

1. Exit from all your VM sessions
2. Run the following

    ```
    vagrant destroy -f
    ```

## VMware-Specific Cleanup

After destroying the VMs, VMware may leave some residual files. If you want to completely clean up:

### Windows
```powershell
# Remove any stale VMware locks
Remove-Item -Recurse -Force "$env:USERPROFILE\Documents\Virtual Machines\*" -ErrorAction SilentlyContinue
```

### Linux/macOS
```bash
# Remove any stale VMware locks
rm -rf ~/vmware/*
```

Next: [Connectivity](./03-connectivity.md)<br/>
Prev: [Prerequisites](./01-prerequisites.md)

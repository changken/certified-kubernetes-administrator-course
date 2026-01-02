# Kubernetes kubeadm 安裝故障排除指南

本文件記錄在 VMware 上使用 kubeadm 安裝 Kubernetes 時遇到的常見問題與解決方案。

---

## 問題總覽

| 問題 | 錯誤訊息 | 解決方案 |
|------|----------|----------|
| Swap 未關閉 | `running with swap on is not supported` | 關閉 swap |
| IP forwarding 未啟用 | `/proc/sys/net/ipv4/ip_forward contents are not set to 1` | 啟用 ip_forward |
| br_netfilter 未載入 | `Failed to check br_netfilter` | 載入 kernel module |
| containerd 未正確設定 | kubelet 持續重啟 | 設定 SystemdCgroup |
| CNI 未初始化 | `cni plugin not initialized` | 重啟 containerd + kubelet |
| CoreDNS Pending | `untolerated taint(s)` | 加入 worker nodes 或移除 taint |

---

## 問題 1：Swap 未關閉

### 錯誤訊息

```
E0102 15:11:14.583809 run.go:72] "command failed" err="failed to run Kubelet: running with swap on is not supported, please disable swap or set --fail-swap-on flag to false"
```

### 解決方案

```bash
# 立即關閉 swap
sudo swapoff -a

# 永久關閉（註解掉 /etc/fstab 的 swap 行）
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 驗證 swap 已關閉（應該顯示 0）
free -h | grep Swap
```

---

## 問題 2：IP Forwarding 未啟用

### 錯誤訊息

```
[ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
```

### 解決方案

```bash
# 啟用 IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# 永久生效
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

# 驗證
cat /proc/sys/net/ipv4/ip_forward
# 應該顯示 1
```

---

## 問題 3：br_netfilter 模組未載入

### 錯誤訊息

```
E0102 15:26:41.012918 main.go:278] Failed to check br_netfilter: stat /proc/sys/net/bridge/bridge-nf-call-iptables: no such file or directory
```

### 解決方案

```bash
# 載入 kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# 確保開機自動載入
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf

# 設定 sysctl 參數
echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf

# 套用設定
sudo sysctl --system

# 驗證
lsmod | grep br_netfilter
cat /proc/sys/net/bridge/bridge-nf-call-iptables
```

---

## 問題 4：containerd 未正確設定

### 症狀

- kubelet 持續重啟（exit code 1）
- `systemctl status kubelet` 顯示 `activating (auto-restart)`

### 解決方案

```bash
# 生成 containerd 設定檔
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# 啟用 SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# 更新 sandbox image（可選，解決警告）
sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.10.1"|' /etc/containerd/config.toml

# 重啟 containerd
sudo systemctl restart containerd
sudo systemctl status containerd
```

---

## 問題 5：CNI Plugin 未初始化

### 錯誤訊息

```
Ready: False - KubeletNotReady - container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

### 解決方案

```bash
# 檢查 CNI 設定檔
ls -la /etc/cni/net.d/

# 檢查 CNI 二進位檔
ls -la /opt/cni/bin/

# 如果 /opt/cni/bin/ 沒有檔案，安裝 CNI plugins
CNI_VERSION="v1.3.0"
sudo mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz

# 重啟 containerd 和 kubelet
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

---

## 問題 6：CoreDNS Pending（Taint 問題）

### 錯誤訊息

```
Warning  FailedScheduling  0/1 nodes are available: 1 node(s) had untolerated taint(s)
```

### 解決方案

#### 方案 1：加入 Worker Nodes（推薦）

```bash
# 在 controlplane 取得 join 指令
kubeadm token create --print-join-command

# 在 worker nodes 執行 join 指令
sudo kubeadm join <controlplane-ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

#### 方案 2：移除 controlplane 的 taint（測試用）

```bash
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-
```

---

## 問題 7：kubeadm init 指令語法錯誤

### 錯誤訊息

```
error: unknown command " " for "kubeadm init"
-bash: --pod-network-cidr=10.244.0.0/16: No such file or directory
```

### 原因

反斜線 `\` 後面有空格，導致換行失效。

### 錯誤寫法

```bash
sudo kubeadm init \
--apiserver-advertise-address=192.168.126.128  \   # ← 空格！
--pod-network-cidr=10.244.0.0/16 \                 # ← 空格！
--upload-certs
```

### 正確寫法

```bash
sudo kubeadm init \
--apiserver-advertise-address=192.168.126.128 \
--pod-network-cidr=10.244.0.0/16 \
--upload-certs
```

或寫成一行：

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.126.128 --pod-network-cidr=10.244.0.0/16 --upload-certs
```

---

## 問題 8：VMware Bridge 網路無法取得 IP

### 症狀

- NAT 網卡 (192.168.126.x) 有 IP
- Bridge 網卡沒有 IP

### 原因

WiFi 網卡（如 Intel AX211/AX210）通常不支援橋接模式，因為 802.11 協議的限制。

### 解決方案

| 連線方式 | 建議 |
|----------|------|
| RJ45 有線網路 | 可使用 BRIDGE 模式 |
| WiFi 無線網路 | 改用 NAT 模式 |

切換到 NAT 模式，編輯 `Vagrantfile`：

```ruby
BUILD_MODE = "NAT"
```

---

## 診斷指令速查

### 檢查節點狀態

```bash
kubectl get nodes
kubectl describe node <node-name>
```

### 檢查所有 Pods

```bash
kubectl get pods -A
kubectl get pods -n kube-system
kubectl get pods -n kube-flannel
```

### 檢查 kubelet

```bash
sudo systemctl status kubelet
journalctl -xeu kubelet --no-pager | tail -50
```

### 檢查 containerd

```bash
sudo systemctl status containerd
sudo crictl ps
sudo crictl images
```

### 檢查網路設定

```bash
# IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Bridge netfilter
cat /proc/sys/net/bridge/bridge-nf-call-iptables

# Kernel modules
lsmod | grep -E "br_netfilter|overlay"
```

### 檢查 CNI

```bash
ls -la /etc/cni/net.d/
ls -la /opt/cni/bin/
```

---

## 重置 kubeadm

如果需要重新開始：

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

---

## 完整安裝流程

參考 [scripts/k8s-prerequisites.sh](./scripts/k8s-prerequisites.sh) 腳本，一次完成所有前置設定。

---

---

## WSL 小技巧：借用 Windows Git Credentials

如果你在 WSL 中 `git push` 遇到認證問題：

```
fatal: could not read Username for 'https://github.com': No such device or address
```

### 解決方案：直接呼叫 Windows 的 Git

WSL 可以直接執行 Windows 程式！Windows 的 Git 通常已經存好 GitHub credentials：

```bash
# 在 WSL 中執行 Windows PowerShell 來 push
powershell.exe -Command "cd 'C:\path\to\repo'; git push origin master"

# 或者用完整路徑
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "git push"
```

### 其他實用的 WSL 互通指令

```bash
# 開啟 Windows 檔案總管到當前目錄
explorer.exe .

# 用 VS Code 開啟專案
code .

# 開啟記事本
notepad.exe file.txt

# 執行 Windows 指令
cmd.exe /c "dir"
```

這個功能讓 WSL 成為真正的 "Best of Both Worlds"！

---

*最後更新：2026 年 1 月*
*Kubernetes 版本：v1.35.0*
*測試環境：VMware Workstation 25H2 + Ubuntu 22.04*

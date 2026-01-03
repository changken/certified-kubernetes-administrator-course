# Node Setup (節點設置)

**注意**<br/>
以下的 shell 指令區塊用 `{ }` 包起來，這樣可以一次複製整個區塊貼到終端機執行。

---

本節將設置節點並安裝 Kubernetes 所需的前置條件（如 container runtime `containerd`）。

**請在所有節點執行**：`controlplane`、`node01`、`node02`

可以使用 tmux 同步模式同時在所有節點執行。

---

## 步驟 1：更新 apt 並安裝基本套件

<!-- 安裝 HTTPS 傳輸、CA 憑證、curl 等基本工具 -->

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```

---

## 步驟 2：載入必要的 Kernel Modules

<!--
overlay: 用於 container 的 overlay filesystem
br_netfilter: 讓 Linux bridge 的封包可以被 iptables 處理（CNI 需要）
-->

```bash
# 載入 kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# 設定開機自動載入
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
```

---

## 步驟 3：設置網路參數 (sysctl)

<!--
bridge-nf-call-iptables: 讓 bridge 網路的封包經過 iptables（Pod 網路需要）
ip_forward: 允許 IP 轉發（Pod 間通訊需要）
這是你之前遇到 Flannel Error 的原因！
-->

```bash
# 立即生效
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl -w net.ipv4.ip_forward=1

# 永久生效（寫入設定檔）
echo -e "net.bridge.bridge-nf-call-iptables=1\nnet.bridge.bridge-nf-call-ip6tables=1\nnet.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/k8s.conf

# 重新載入所有 sysctl 設定
sudo sysctl --system
```

---

## 步驟 4：安裝 Container Runtime (containerd)

<!-- containerd 是 Kubernetes 使用的容器執行環境 -->

```bash
sudo apt-get install -y containerd
```

---

## 步驟 5：設定 containerd 使用 systemd cgroup

<!--
重要！很多學生會漏掉這步
如果沒設定，會導致 pods crashloop，kubectl 會報錯：
"The connection to the server x.x.x.x:6443 was refused"
-->

```bash
# 建立設定目錄
sudo mkdir -p /etc/containerd

# 產生預設設定並修改 SystemdCgroup = true
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml

# 重啟 containerd
sudo systemctl restart containerd
```

---

## 步驟 6：取得最新 Kubernetes 版本號

<!-- 動態取得最新穩定版的主版本號（如 v1.35） -->

```bash
KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')
echo "將安裝 Kubernetes ${KUBE_LATEST}"
```

---

## 步驟 7：下載 Kubernetes 的 GPG 金鑰

<!-- 用於驗證 apt repository 的套件簽名 -->

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

---

## 步驟 8：新增 Kubernetes apt repository

<!-- 加入官方的 Kubernetes 套件來源 -->

```bash
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

---

## 步驟 9：安裝 kubelet, kubeadm, kubectl

<!--
kubelet: 在每個節點上運行，管理 Pod
kubeadm: 用於建立/加入 cluster 的工具
kubectl: 用於操作 cluster 的 CLI 工具
apt-mark hold: 鎖定版本，避免意外升級
-->

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 步驟 10：設定 crictl

<!-- crictl 是用來除錯 container 的工具，設定它連接到 containerd -->

```bash
sudo crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock
```

---

## 步驟 11：設定 kubelet 使用正確的 IP

<!--
VirtualBox VM 有多個網路介面（NAT + Bridge）
需要指定 kubelet 使用正確的 IP，否則節點間無法通訊
PRIMARY_IP 是 Vagrant 在 setup-hosts.sh 中設定的環境變數
-->

```bash
echo "KUBELET_EXTRA_ARGS='--node-ip ${PRIMARY_IP}'" | sudo tee /etc/default/kubelet
```

---

## 完成！

以上步驟完成後，可以進行下一步：

- **Controlplane 節點**：執行 `kubeadm init`
- **Worker 節點**：執行 `kubeadm join`

---

下一步：[Control Plane 設置](./05-controlplane.md)

[Kubernetes 官方文件](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

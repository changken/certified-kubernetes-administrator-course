# Control Plane 設置（僅在 controlplane 節點執行）

---

## 步驟 1：設定網路 CIDR 變數

<!--
POD_CIDR: Pod 網路範圍，Flannel 預設使用 10.244.0.0/16
SERVICE_CIDR: Service (ClusterIP) 網路範圍
注意：這些範圍不能與你的家用網路重疊（通常是 192.168.0.0/24）
-->

```bash
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
```

---

## 步驟 2：初始化 Control Plane

<!--
kubeadm init 會：
1. 產生 CA 憑證和其他必要憑證
2. 產生 kubeconfig 檔案
3. 啟動 etcd, kube-apiserver, kube-controller-manager, kube-scheduler
4. 產生 worker node 加入用的 token

參數說明：
--pod-network-cidr: Pod 網路範圍（必須與 CNI 設定一致）
--service-cidr: Service 網路範圍
--apiserver-advertise-address: API Server 監聽的 IP（使用 PRIMARY_IP 環境變數）
-->

```bash
sudo kubeadm init --pod-network-cidr $POD_CIDR --service-cidr $SERVICE_CIDR --apiserver-advertise-address $PRIMARY_IP
```

**重要！** 執行完成後，會顯示類似以下的 `kubeadm join` 指令，**請複製保存**：

```
kubeadm join 192.168.x.x:6443 --token xxxxx.xxxxxxxxxxxxxxxx \
    --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## 步驟 3：設定 kubectl 權限

<!--
kubeadm init 產生的 admin.conf 在 /etc/kubernetes/admin.conf
需要複製到當前用戶的 ~/.kube/config 才能使用 kubectl
-->

```bash
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

驗證：

```bash
kubectl get nodes
```

此時 controlplane 應該是 `NotReady` 狀態（因為還沒安裝 CNI）。

---

## 步驟 4：安裝 CNI 網路外掛

CNI（Container Network Interface）負責 Pod 之間的網路通訊。

### 選項 A：使用 Flannel（簡單）

<!--
Flannel 是最簡單的 CNI，但不支援 Network Policy
適合學習和簡單環境
-->

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### 選項 B：使用 Calico（支援 Network Policy）

<!--
Calico 功能更完整，支援 Network Policy（CKA 考試會考）
步驟較多，但建議使用
-->

```bash
# 1. 安裝 Tigera Operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.1/manifests/tigera-operator.yaml

# 2. 下載 Calico 設定檔
curl -LO https://raw.githubusercontent.com/projectcalico/calico/v3.30.1/manifests/custom-resources.yaml

# 3. 修改 Pod CIDR（從預設 192.168.0.0/16 改為我們設定的 10.244.0.0/16）
sed -i "s#192.168.0.0/16#$POD_CIDR#" custom-resources.yaml

# 4. 套用設定
kubectl apply -f custom-resources.yaml
```

等待 Calico 就緒：

```bash
watch kubectl get tigerastatus
```

所有項目都顯示 `True` 後，按 `Ctrl+C` 退出。

---

## 步驟 5：驗證 Control Plane

```bash
# 檢查節點狀態（應該變成 Ready）
kubectl get nodes

# 檢查系統 Pod 狀態（應該全部 Running）
kubectl get pods -n kube-system

# 如果用 Calico，也檢查 calico 的 Pod
kubectl get pods -n calico-system
```

---

## 常見問題排錯

### 問題 1：coredns 卡在 ContainerCreating

**原因**：CNI 沒裝好或 Flannel/Calico 有問題

```bash
# 檢查 CNI Pod 日誌
kubectl logs -n kube-flannel -l app=flannel
# 或
kubectl logs -n calico-system -l k8s-app=calico-node
```

### 問題 2：kubeadm init 失敗

**原因**：前置條件沒設好

```bash
# 重置後重試
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf ~/.kube

# 確認前置條件
sudo sysctl net.ipv4.ip_forward
sudo sysctl net.bridge.bridge-nf-call-iptables
lsmod | grep br_netfilter
```

### 問題 3：忘記複製 join 指令

```bash
# 重新產生 join 指令
kubeadm token create --print-join-command
```

---

下一步：[Worker 節點加入](./06-workers.md)

[Kubernetes 官方文件](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

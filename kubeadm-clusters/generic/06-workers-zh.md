# Worker 節點加入（在 node01、node02 執行）

---

## 前置條件

確保你已經：
1. 完成 [04-node-setup-zh.md](./04-node-setup-zh.md) 的所有步驟（在所有節點）
2. 完成 [05-controlplane-zh.md](./05-controlplane-zh.md)（在 controlplane）
3. 保存了 `kubeadm join` 指令

---

## 步驟 1：取得 Join 指令

如果你忘記複製 `kubeadm init` 輸出的 join 指令，可以在 **controlplane** 重新產生：

```bash
kubeadm token create --print-join-command
```

會輸出類似：

```
kubeadm join 192.168.18.74:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:xxxx...
```

---

## 步驟 2：加入 Worker 節點

在 **node01** 和 **node02** 分別執行：

<!--
kubeadm join 會：
1. 下載 cluster 的 CA 憑證
2. 產生 kubelet 的憑證
3. 啟動 kubelet 並向 API Server 註冊
-->

```bash
# 切換到 root
sudo -i

# 貼上 join 指令（從 controlplane 複製的）
kubeadm join 192.168.x.x:6443 --token xxxxx.xxxxxxxxxxxxxxxx \
    --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

成功會看到：

```
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

---

## 步驟 3：驗證（在 controlplane 執行）

```bash
kubectl get nodes
```

應該看到 3 個節點都是 `Ready`：

```
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   10m     v1.35.0
node01         Ready    <none>          2m      v1.35.0
node02         Ready    <none>          1m      v1.35.0
```

檢查所有 Pod 狀態：

```bash
kubectl get pods -A
```

所有 Pod 應該都是 `Running` 狀態。

---

## 常見問題排錯

### 問題 1：Token 過期

Token 預設 24 小時後過期。

```bash
# 在 controlplane 重新產生
kubeadm token create --print-join-command
```

### 問題 2：節點一直 NotReady

**原因**：CNI 沒有正確安裝或網路問題

```bash
# 在 controlplane 檢查 CNI Pod
kubectl get pods -n kube-flannel
# 或
kubectl get pods -n calico-system

# 在 worker 節點檢查 kubelet 日誌
sudo journalctl -u kubelet -f
```

### 問題 3：連不上 API Server

**原因**：網路不通或防火牆

```bash
# 在 worker 節點測試連線
curl -k https://192.168.x.x:6443

# 檢查 controlplane IP 是否正確
ping 192.168.x.x
```

### 問題 4：需要重新加入節點

```bash
# 在 worker 節點重置
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d

# 重新執行 join 指令
```

---

## 為 Worker 節點加上 Role 標籤（選用）

預設 worker 節點的 ROLES 欄位是 `<none>`，可以加上標籤：

```bash
# 在 controlplane 執行
kubectl label node node01 node-role.kubernetes.io/worker=worker
kubectl label node node02 node-role.kubernetes.io/worker=worker
```

再次查看：

```bash
kubectl get nodes
```

```
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   10m     v1.35.0
node01         Ready    worker          2m      v1.35.0
node02         Ready    worker          1m      v1.35.0
```

---

下一步：[測試 Cluster](./07-test.md)

[Kubernetes 官方文件](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/)

# 測試 Cluster（在 controlplane 執行）

這裡我們將部署一個 nginx 應用並透過 NodePort 服務來驗證 cluster 是否正常運作。

---

## 步驟 1：部署 nginx 並建立 NodePort Service

<!--
kubectl create deployment: 建立一個 Deployment（會自動建立 Pod）
kubectl expose: 將 Deployment 暴露為 Service
--type=NodePort: 使用 NodePort 類型，可以從叢集外部存取
--port 80: 容器內部的 port
-->

```bash
# 建立 nginx deployment
kubectl create deployment nginx --image nginx:alpine

# 等待 Pod 就緒
kubectl wait deployment nginx --for condition=Available=True --timeout=90s

# 建立 NodePort Service
kubectl expose deploy nginx --type=NodePort --port 80

# 取得分配的 NodePort 號碼
PORT_NUMBER=$(kubectl get service -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
echo "Service 已建立，NodePort: $PORT_NUMBER"
```

---

## 步驟 2：驗證服務

<!--
NodePort 會在所有節點上開放同一個 port（30000-32767 範圍）
可以透過任何節點的 IP + NodePort 存取服務
-->

```bash
# 透過 node01 存取
curl http://node01:$PORT_NUMBER

# 透過 node02 存取
curl http://node02:$PORT_NUMBER
```

如果看到類似以下的 HTML 內容，表示成功：

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

### 遇到 Connection refused？

```
curl: (7) Failed to connect to node01 port 30659 after 0 ms: Connection refused
```

等幾秒再試一次，Pod 可能還在啟動中。

---

## 步驟 3：從瀏覽器存取（Bridge 網路模式）

如果你使用 Bridge 網路模式（VirtualBox 預設），可以從 Windows/Mac 的瀏覽器存取：

```bash
# 取得瀏覽器可用的 URL
echo "http://$(dig +short node01):$PORT_NUMBER"
```

把輸出的 URL 貼到瀏覽器，應該會看到 nginx 歡迎頁面。

---

## 額外驗證指令

```bash
# 查看所有資源
kubectl get all

# 查看 Pod 詳細資訊
kubectl get pods -o wide

# 查看 Service 詳細資訊
kubectl get svc nginx

# 查看 Pod 日誌
kubectl logs -l app=nginx
```

輸出範例：

```
NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE
pod/nginx-7c5ddbdf54-xxxxx   1/1     Running   0          1m    10.244.1.2   node01

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        30m
service/nginx        NodePort    10.96.45.123   <none>        80:31234/TCP   1m

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           1m
```

---

## 清理測試資源（選用）

```bash
kubectl delete deployment nginx
kubectl delete service nginx
```

---

## 恭喜！

你已經成功建立了一個可運作的 Kubernetes Cluster！

### 你學到了什麼：

| 步驟 | 學習內容 |
|------|---------|
| 04-node-setup | kernel modules, sysctl, containerd, kubeadm 安裝 |
| 05-controlplane | kubeadm init, CNI 安裝, kubeconfig 設定 |
| 06-workers | kubeadm join, 節點加入 |
| 07-test | Deployment, Service, NodePort |

### 接下來可以練習：

- 部署多副本應用：`kubectl scale deployment nginx --replicas=3`
- 建立不同類型的 Service（ClusterIP, LoadBalancer）
- 使用 ConfigMap 和 Secret
- 設定 Network Policy（需要 Calico）
- 練習 Pod 排程（nodeSelector, affinity）

---

上一步：[Worker 節點加入](./06-workers-zh.md)

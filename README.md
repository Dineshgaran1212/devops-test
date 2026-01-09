# 🚀 Target Application - Kubernetes Deployment

Production-ready Flask application with MySQL backend, containerized and deployable to Kubernetes using Helm.

## ✅ What's Included

✅ **Containerization** - Production Dockerfile (Python 3.9, non-root, 150MB)  
✅ **Kubernetes** - Complete Helm chart with 12 templates  
✅ **Network** - Ingress for `target.example.com` + Network Policies  
✅ **CI/CD** - GitLab pipeline with semantic versioning  
✅ **Security** - SQL injection fixed, secrets externalized, RBAC, Network Policies  

> 📘 **First time?** Follow the steps below to deploy in 10 minutes.

---

## 📋 Prerequisites

Install these tools before starting:

| Tool | Version | Check Command |
|------|---------|---------------|
| Docker | 20.10+ | `docker --version` |
| Kubernetes | 1.34+ | `kubectl version --client` |
| Helm | 3.17+ | `helm version --short` |

---

## 🚀 Deployment Steps

### Step 1: Enable Kubernetes

**Docker Desktop:**
1. Open Docker Desktop → Settings → Kubernetes
2. Check ✅ Enable Kubernetes
3. Click Apply & Restart
4. Wait for green indicator

**Verify:**
```powershell
kubectl config use-context docker-desktop
kubectl cluster-info
kubectl get nodes
```

Expected: `docker-desktop` node in `Ready` status.

---

### Step 2: Install NGINX Ingress Controller

```powershell
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready (1-2 minutes)
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s
```

**Verify:**
```powershell
kubectl get pods -n ingress-nginx
```

Expected: `ingress-nginx-controller` pod `Running` and `1/1` ready.

---

### Step 3: Add Domain to Hosts File

**Windows (PowerShell as Administrator):**
```powershell
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "`n127.0.0.1 target.example.com"
```

**Linux/Mac:**
```bash
echo "127.0.0.1 target.example.com" | sudo tee -a /etc/hosts
```

**Verify:**
```powershell
# Windows
Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" | Select-String "target.example.com"

# Linux/Mac
cat /etc/hosts | grep target.example.com
```

---

### Step 4: Build Docker Image

```bash
docker build -t target-web-app:1.0.0 .
```

**Verify:**
```bash
docker images | grep target-web-app
```

Expected: Image `target-web-app:1.0.0` (~150MB).

---

### Step 5: Deploy with Helm

**Docker Desktop:**
```powershell
helm install target-app ./helm/target-app `
  --set web.image.repository=target-web-app `
  --set web.image.tag=1.0.0 `
  --set web.image.pullPolicy=Never `
  --set mysql.auth.rootPassword=MySecurePass123 `
  --set mysql.auth.password=MySecurePass123 `
  --kube-context=docker-desktop
```

**Minikube:**
```bash
# Load image first
minikube image load target-web-app:1.0.0

# Deploy
helm install target-app ./helm/target-app \
  --set web.image.repository=target-web-app \
  --set web.image.tag=1.0.0 \
  --set web.image.pullPolicy=Never \
  --set mysql.auth.rootPassword=MySecurePass123 \
  --set mysql.auth.password=MySecurePass123
```

**Wait for pods to start:**
```bash
kubectl get pods --watch
```

Press `Ctrl+C` when all pods show `Running` and ready (2-3 minutes).

---

### Step 6: Verify Deployment

```bash
# Check all resources
kubectl get all

# Check network policies
kubectl get networkpolicy

# Check ingress
kubectl get ingress
```

**Expected:**
- ✅ 2 web pods: `Running`
- ✅ 1 MySQL pod: `Running`
- ✅ 2 Network Policies deployed
- ✅ Ingress ADDRESS: `localhost`

---

### Step 7: Access Application

**Browser:**
- Open: http://target.example.com

**Command Line:**
```bash
# Test health endpoint
curl http://target.example.com/health

# Test application
curl http://target.example.com/
```

Expected: Application page with "Targets" title.

---

## 📝 Common Commands

### View Logs
```bash
# Web application logs
kubectl logs -l app.kubernetes.io/component=web -f

# MySQL logs
kubectl logs -l app.kubernetes.io/component=database -f
```

### Check Status
```bash
# All resources
kubectl get all

# Specific resources
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl get networkpolicy

# Helm release
helm list
helm status target-app
```

### Update Deployment
```bash
# Change image version
helm upgrade target-app ./helm/target-app \
  --set web.image.tag=1.1.0 \
  --reuse-values
```

### Rollback
```bash
# View history
helm history target-app

# Rollback to previous
helm rollback target-app
```

### Delete Deployment
```bash
# Uninstall application
helm uninstall target-app

# Verify removal
kubectl get all
```

---

## 🔧 Troubleshooting

### Pods Not Starting
```bash
# Describe pod
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
```

### MySQL Crash (Password Error)
```bash
# Check MySQL logs
kubectl logs target-app-mysql-0

# If password error, upgrade with passwords:
helm upgrade target-app ./helm/target-app \
  --set mysql.auth.rootPassword=YourPassword \
  --set mysql.auth.password=YourPassword \
  --reuse-values
```

### Application Not Accessible
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check hosts file
Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" | Select-String "target.example.com"

# Direct access (bypass ingress)
kubectl port-forward svc/target-app-web 8080:80
# Then open: http://localhost:8080
```

---

## 📚 Additional Documentation

- **[DEPLOYMENT-RUNBOOK.md](DEPLOYMENT-RUNBOOK.md)** - Complete deployment guide with troubleshooting
- **[BUGS-AND-FIXES.md](BUGS-AND-FIXES.md)** - All 14 bugs found and fixed
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and design
- **[CI-CD-GUIDE.md](CI-CD-GUIDE.md)** - CI/CD pipeline documentation
- **[SECURITY-IMPLEMENTATION-SUMMARY.md](SECURITY-IMPLEMENTATION-SUMMARY.md)** - Security controls

---

## ✅ Assessment Requirements

| Requirement | Status | Location |
|------------|--------|----------|
| Containerization | ✅ | `Dockerfile` |
| Kubernetes Deployment | ✅ | `helm/target-app/` |
| Helm Chart | ✅ | `helm/target-app/` |
| Ingress (`target.example.com`) | ✅ | `helm/target-app/templates/ingress.yaml` |
| Network Policies | ✅ | `helm/target-app/templates/networkpolicy.yaml` |
| CI/CD Pipeline | ✅ | `.gitlab-ci.yml` |

---

**🎉 Deployment complete! Application accessible at http://target.example.com**


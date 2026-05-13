# 🚀 My DevOps: Full Stack Infrastructure & CI/CD with K3s

โปรเจกต์นี้เป็นการจำลองระบบ Infrastructure แบบครบวงจร ตั้งแต่การสร้างเครื่องเซิร์ฟเวอร์จำลอง ไปจนถึงการทำ CI/CD เพื่อ Deploy แอปพลิเคชัน Bun.js ลงบน Kubernetes (K3s) ทั้งหมดรันอยู่บนเครื่อง Local ผ่าน Docker

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Windows Host                                           │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │  Docker Container (my-ubuntu) - Terraform       │   │
│   │                                                 │   │
│   │   ┌──────────┐  ┌──────────┐  ┌─────────────┐  │   │
│   │   │  Docker   │  │   K3s    │  │  GitHub      │  │   │
│   │   │ (nested)  │  │ (v1.26)  │  │  Runner      │  │   │
│   │   └──────────┘  └────┬─────┘  └─────────────┘  │   │
│   │                      │                          │   │
│   │          ┌───────────┼───────────┐              │   │
│   │          │           │           │              │   │
│   │     ┌────▼───┐  ┌───▼────┐  ┌───▼──────┐      │   │
│   │     │Traefik │  │ my-app │  │Dashboard │      │   │
│   │     │Ingress │  │ (Bun)  │  │  (GUI)   │      │   │
│   │     │ :80    │  │ :3000  │  │  :443    │      │   │
│   │     └────────┘  └────────┘  └──────────┘      │   │
│   │                                                 │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
│   Port Mapping: 8080→80 | 3000→3000 | 3001→3001        │
│                 6443→6443 | 2222→22                     │
└─────────────────────────────────────────────────────────┘
```

### Pipeline Flow

```
git push → GitHub Actions → Build Docker Image → Push to GHCR
                ↓
       Self-hosted Runner (ภายใน Container)
                ↓
       kubectl apply → K3s Deploy → Rollout Restart
```

---

## 📋 Prerequisites

ก่อนเริ่มต้นใช้งาน ต้องติดตั้งซอฟต์แวร์ต่อไปนี้บนเครื่อง:

| ซอฟต์แวร์    | เวอร์ชันขั้นต่ำ | หมายเหตุ                          |
|--------------|-----------------|-----------------------------------|
| Docker       | 20.10+          | สำหรับรัน Container               |
| Terraform    | 1.0+            | สำหรับสร้าง Infrastructure        |
| Ansible      | 2.9+ (via WSL)  | สำหรับจัดการ Configuration        |
| kubectl      | 1.26+           | สำหรับจัดการ Kubernetes           |
| Bun          | 1.2+            | สำหรับ Development เท่านั้น       |
| Git          | 2.30+           | สำหรับ Version Control            |

---

## 📁 Directory Structure

```
my-devops/
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD Pipeline (GitHub Actions)
├── Ansible/
│   ├── inventory.ini           # รายชื่อเซิร์ฟเวอร์เป้าหมาย
│   ├── playbook.yml            # ติดตั้ง Docker + K3s
│   ├── dashboard.yml           # ติดตั้ง Kubernetes Dashboard
│   └── runner.yml              # ติดตั้ง GitHub Self-hosted Runner
├── k8s/
│   └── deployment.yml          # Kubernetes Deployment + Service
├── terraform/
│   ├── main.tf                 # สร้าง Docker Container (Ubuntu)
│   ├── variables.tf            # ตัวแปรสำหรับ Terraform
│   └── outputs.tf              # ค่าที่แสดงหลังจากสร้างเสร็จ
├── index.ts                    # โค้ดหลักของแอป (Bun.js, port 3000)
├── Dockerfile                  # สร้าง Docker Image ของแอป
├── package.json                # Dependencies และ Scripts
├── tsconfig.json               # TypeScript Configuration
├── bun.lock                    # Bun Lock File
├── .dockerignore               # ไฟล์ที่ไม่ต้อง Copy เข้า Image
├── .gitignore                  # ไฟล์ที่ไม่ต้อง Commit
└── README.md                   # ไฟล์ที่คุณกำลังอ่านอยู่นี้
```

---

## 🛠️ How to Use

### Step 1: สร้าง Infrastructure ด้วย Terraform

```bash
cd terraform
terraform init
terraform apply
```

คำสั่งนี้จะสร้าง Docker Container ชื่อ `my-ubuntu` (Ubuntu 22.04, privileged mode) พร้อมเปิดพอร์ตที่จำเป็นทั้งหมด

### Step 2: ติดตั้งระบบด้วย Ansible (รันผ่าน WSL)

```bash
cd Ansible

# ติดตั้ง Docker + K3s ภายใน Container
ansible-playbook -i inventory.ini playbook.yml

# ติดตั้ง Kubernetes Dashboard
ansible-playbook -i inventory.ini dashboard.yml

# ติดตั้ง GitHub Self-hosted Runner
ansible-playbook -i inventory.ini runner.yml
```

### Step 3: Push โค้ดเพื่อ Trigger CI/CD

```bash
git add .
git commit -m "deploy: update application"
git push origin master
```

GitHub Actions จะทำงานอัตโนมัติ:
1. **Job: build-and-push** — Build Docker Image แล้ว Push ไปยัง GHCR
2. **Job: deploy** — ใช้ Self-hosted Runner สั่ง `kubectl apply` และ `kubectl rollout restart`

### Step 4: ตั้งค่า Ingress (ครั้งแรกเท่านั้น)

```bash
docker exec my-ubuntu sh -c "cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
EOF"
```

---

## 🌐 Port Mapping

| Windows (Host) | Docker (Container) | Service               | Protocol |
|:--------------:|:-------------------:|------------------------|:--------:|
| 8080           | 80                  | แอปพลิเคชัน (Traefik → Bun.js) | HTTP     |
| 3000           | 3000                | Reserved               | TCP      |
| 3001           | 3001                | Kubernetes Dashboard   | HTTPS    |
| 6443           | 6443                | K3s API Server         | HTTPS    |
| 2222           | 22                  | SSH                    | TCP      |

### การเข้าใช้งาน

| Service              | URL                           | หมายเหตุ                           |
|----------------------|-------------------------------|------------------------------------|
| **แอปพลิเคชัน**      | http://localhost:8080         | ผ่าน Traefik Ingress               |
| **K8s Dashboard**    | https://127.0.0.1:3001       | ต้องใช้ Token เพื่อ Login           |

---

## 🔑 Useful Commands

### จัดการ Kubernetes

```bash
# ดู Pod ทั้งหมด
docker exec my-ubuntu kubectl get pods -A

# ดู Service ทั้งหมด
docker exec my-ubuntu kubectl get svc -A

# ดู Log ของแอป
docker exec my-ubuntu kubectl logs -f deployment/my-app

# Restart แอป
docker exec my-ubuntu kubectl rollout restart deployment my-app
```

### จัดการ Dashboard

```bash
# สร้าง Token สำหรับ Login
docker exec my-ubuntu kubectl -n kubernetes-dashboard create token admin-user

# เปิด Port-forward สำหรับ Dashboard (ถ้า NodePort ไม่ได้ตั้ง)
docker exec my-ubuntu kubectl port-forward -n kubernetes-dashboard \
  service/kubernetes-dashboard 3001:443 --address 0.0.0.0
```

### ใช้ kubectl จากเครื่อง Windows โดยตรง

```powershell
# ดึง Kubeconfig ออกมา
docker exec my-ubuntu cat /etc/rancher/k3s/k3s.yaml > k3s_config.yaml

# ตั้งค่า KUBECONFIG
$env:KUBECONFIG=".\k3s_config.yaml"

# ใช้คำสั่ง kubectl ได้ตามปกติ
kubectl get pods -A
```

---

## 🐛 Troubleshooting

### Dashboard เข้าไม่ได้ (ERR_TIMED_OUT)
**สาเหตุ:** Port-forward หลุดหลังจาก Deploy หรือปิด Terminal
**วิธีแก้:**
```bash
# รัน Port-forward ใหม่ภายใน Container
docker exec my-ubuntu kubectl port-forward -n kubernetes-dashboard \
  service/kubernetes-dashboard 3001:443 --address 0.0.0.0

# หรือรันจาก Windows (แนะนำ เสถียรกว่า)
$env:KUBECONFIG=".\k3s_config.yaml"
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 3001:443
```

### แอปแสดง 404 page not found
**สาเหตุ:** ยังไม่ได้สร้าง Ingress ให้ Traefik รู้จักแอปของคุณ
**วิธีแก้:** ทำตามขั้นตอน Step 4 ในหัวข้อ How to Use

### kubectl บน Windows ขึ้น Error "couldn't get current server API group list"
**สาเหตุ:** `kubectl` เวอร์ชันบน Windows ไม่ตรงกับ K3s API
**วิธีแก้:** ใช้คำสั่งผ่าน `docker exec` แทน
```bash
docker exec my-ubuntu kubectl <คำสั่ง>
```

---

## 🌟 Tech Stack

| เครื่องมือ       | บทบาท                                  |
|-----------------|----------------------------------------|
| **Bun.js**      | Runtime สำหรับแอปพลิเคชัน              |
| **Docker**      | Containerization ทั้งแอปและ Infra       |
| **K3s**         | Lightweight Kubernetes Orchestrator     |
| **Terraform**   | Infrastructure as Code (IaC)            |
| **Ansible**     | Configuration Management & Automation   |
| **GitHub Actions** | CI/CD Pipeline                       |
| **Traefik**     | Ingress Controller (มาพร้อม K3s)       |
| **GHCR**        | Container Registry สำหรับเก็บ Image     |

---

*Created with ❤️ for DevOps Learning*

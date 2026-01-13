# Deploy TEI on EC2

Quick setup for Text Embeddings Inference on a t3.micro instance.

## Launch Instance

1. **Name**: `tei-server`

2. **AMI**: Amazon Linux 2023 (default)

3. **Instance type**: t3.micro

4. **Key pair**: Create new key pair (save the .pem file)

5. **Storage**: 8 GB gp3 (default)

6. **Network settings** → Edit → Add security group rule:
   - Type: Custom TCP
   - Port range: `8080`
   - Source type: Anywhere

7. **Advanced details** → User data:

```bash
#!/bin/bash
set -euxo pipefail

dnf install -y ca-certificates procps docker
systemctl enable --now docker

mkdir -p /opt/tei/lib

TEI_IMAGE="ghcr.io/huggingface/text-embeddings-inference:cpu-1.8.2"
CID=$(docker create ${TEI_IMAGE})

docker cp ${CID}:/usr/local/bin/text-embeddings-router /opt/tei/
docker cp ${CID}:/usr/lib/llvm-14/lib/libomp.so.5 /opt/tei/lib/libomp.so.5
docker rm ${CID}

ln -s libomp.so.5 /opt/tei/lib/libiomp5.so
chmod +x /opt/tei/text-embeddings-router

fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

cat >/etc/systemd/system/tei.service <<'EOF'
[Unit]
Description=Text Embeddings Inference
After=network.target

[Service]
Type=simple
Environment=LD_LIBRARY_PATH=/opt/tei/lib
Environment=OMP_NUM_THREADS=1
Environment=TOKENIZERS_PARALLELISM=false
ExecStart=/opt/tei/text-embeddings-router --model-id nomic-ai/nomic-embed-text-v1.5 --port 8080 --max-batch-tokens 1024
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tei
```

8. Click **Launch instance**

## Wait for Startup

The instance needs ~3-5 minutes to:
- Install dependencies
- Download the model
- Start the service

## Test

```shell
curl http://<public-ip>:8080/embed \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"inputs": "Hello world"}'
```

## SSH Access (optional)

```shell
chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@<public-ip>

# Check service status
sudo systemctl status tei

# View logs
sudo journalctl -u tei -f
```

## Add Elastic Load Balancer (ALB) + Auto Scaling (Optional but Powerful)

To make this setup **horizontally scalable and highly available**, you can place the TEI instances behind an **Application Load Balancer (ALB)** and run them in an **Auto Scaling Group (ASG)**.

This turns your single free-tier instance into a **distributed embeddings service** that can scale out automatically under load.

---

### Architecture Overview

```
Clients
   │
   ▼
Application Load Balancer (HTTP :80)
   │
   ▼
Target Group (port 8080)
   │
   ├── t3.micro (TEI)
   ├── t3.micro (TEI)
   └── t3.micro (TEI)
        (Auto Scaling Group)
```

Each instance runs the same systemd-based TEI service you already set up.

---

## Step 1: Create a Target Group

1. Go to **EC2 → Target Groups → Create target group**
2. **Target type**: Instance
3. **Protocol**: HTTP
4. **Port**: `8080`
5. **VPC**: same VPC as your instances
6. **Health check**:

   * Protocol: HTTP
   * Path: `/health`
   * Healthy threshold: 2
   * Unhealthy threshold: 2

> TEI exposes `/health` automatically — no extra config needed.

Create the target group but **do not register instances yet**.

---

## Step 2: Create an Application Load Balancer

1. Go to **EC2 → Load Balancers → Create load balancer**
2. Choose **Application Load Balancer**
3. Name: `tei-alb`
4. **Scheme**: Internet-facing
5. **IP address type**: IPv4
6. **Listeners**:

   * HTTP :80
7. **Availability Zones**:

   * Select at least 2 AZs
8. **Security group**:

   * Allow inbound HTTP (port 80) from your desired sources

Attach the **target group** you created earlier.

---

## Step 3: Create a Launch Template

1. Go to **EC2 → Launch Templates → Create launch template**
2. Base it on your working instance:

   * AMI: Amazon Linux 2023
   * Instance type: `t3.micro`
   * Key pair: optional (for debugging)
   * Security group:

     * Allow inbound **8080 from ALB security group**
3. **Advanced details → User data**:

   * Paste **the exact same user-data script** from your single-instance setup

This ensures every new instance automatically installs and starts TEI.

---

## Step 4: Create an Auto Scaling Group

1. Go to **EC2 → Auto Scaling Groups → Create**
2. Use the launch template you just created
3. **VPC**: same VPC
4. **Subnets**: at least 2 (different AZs)
5. **Attach to existing load balancer**

   * Choose your ALB target group
6. **Scaling configuration**:

   * Min: `1`
   * Desired: `1`
   * Max: `N` (e.g. 5 or 10)

---

## Step 5: Configure Auto Scaling Policy

A simple and effective policy:

**Target tracking scaling**

* Metric: **Average CPU Utilization**
* Target value: `60%`

Optional alternatives:

* ALB `RequestCountPerTarget`
* ALB `TargetResponseTime`

CPU works well because TEI is CPU-bound.

---

## Step 6: Update Your Client Requests

Instead of calling the instance IP:

```bash
curl http://<alb-dns-name>/embed \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"inputs": "Hello world"}'
```

The ALB will automatically distribute requests across instances.

---

## Why This Works So Well for Embeddings

* **Stateless requests** → perfect load balancing
* **CPU-bound inference** → clean horizontal scaling
* **Slow tolerance** → cold starts are acceptable
* **Cheap nodes** → failures don’t matter

You get:

* High availability
* Automatic recovery
* Linear throughput scaling
* Predictable cost

All without GPUs.

---

## Notes & Best Practices

* **Warm-up time**: new instances may take a few minutes to download the model — ALB health checks handle this safely.
* **Security**:

  * Restrict instance port 8080 to ALB only
  * Optionally add auth or IP allowlists at ALB level
* **HTTPS**:

  * Add an ACM certificate to the ALB listener for TLS
* **Spot instances**:

  * Great for batch embedding jobs

---

### Summary

Adding **ALB + Auto Scaling** transforms this from:

> “a clever free-tier hack”

into:

> **a production-grade, horizontally scalable embeddings service built entirely on CPUs**.

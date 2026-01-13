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

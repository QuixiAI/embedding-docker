# Running TEI Natively

Native installation of Text Embeddings Inference for running Gemma Embeddings 300m.

## Prerequisites

### Install Rust (all platforms)

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### Clone TEI

```shell
git clone https://github.com/huggingface/text-embeddings-inference.git
cd text-embeddings-inference
```

---

## macOS

### Apple Silicon (M1/M2/M3)

```shell
cargo install --path router -F metal
```

### Intel Mac

```shell
cargo install --path router -F ort
```

---

## Linux

### CPU

```shell
# Install dependencies
sudo apt-get install libssl-dev gcc -y

# Build with ONNX backend
cargo install --path router -F ort
```

### NVIDIA GPU

Requires CUDA 12.2+ and compatible drivers.

```shell
sudo apt-get install libssl-dev gcc -y
export PATH=$PATH:/usr/local/cuda/bin

# Ampere/Ada/Hopper (A100, A10, RTX 4000 series, H100)
cargo install --path router -F candle-cuda

# Turing (T4, RTX 2000 series)
cargo install --path router -F candle-cuda-turing
```

---

## Windows

Native Windows is not officially supported. Use **WSL 2** and follow the Linux instructions above.

---

## Run the Server

```shell
text-embeddings-router --model-id unsloth/embeddinggemma-300m --port 8080
```

## Test

```shell
curl http://localhost:8080/embed \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"inputs": "Hello world"}'
```

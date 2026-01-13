# Compiling TEI for Windows

Native compilation of Text Embeddings Inference on Windows for running Gemma Embeddings 300m.

## Prerequisites

### Install Rust

Download and run the installer from https://rustup.rs/ or use winget:

```powershell
winget install Rustlang.Rustup
```

Restart your terminal after installation.

### Install Visual Studio Build Tools

TEI requires the MSVC compiler. Install Visual Studio Build Tools with the C++ workload:

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

Then open Visual Studio Installer and add "Desktop development with C++".

### Clone TEI

```powershell
git clone https://github.com/huggingface/text-embeddings-inference.git
cd text-embeddings-inference
```

---

## Build

### CPU (ONNX Runtime)

```powershell
cargo install --path router -F ort
```

### NVIDIA GPU (CUDA)

Requires CUDA 12.2+ and cuDNN installed. Ensure `nvcc` is in your PATH.

```powershell
# Ampere/Ada (RTX 3000 series, RTX 4000 series)
cargo install --path router -F candle-cuda

# Turing (RTX 2000 series)
cargo install --path router -F candle-cuda-turing
```

---

## Run the Server

```powershell
text-embeddings-router --model-id unsloth/embeddinggemma-300m --port 8080
```

## Test

```powershell
curl http://localhost:8080/embed -X POST -H "Content-Type: application/json" -d "{\"inputs\": \"Hello world\"}"
```

Or with PowerShell:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/embed" -Method Post -ContentType "application/json" -Body '{"inputs": "Hello world"}'
```

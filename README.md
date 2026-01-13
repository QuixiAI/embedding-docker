# Embedding Service

A local text embedding service using HuggingFace's Text Embeddings Inference server.

## Prerequisites

- Docker
- `jq` (for the CLI tool)
- `curl`

## Quick Start

```bash
# Start the service and wait until ready
./setup.sh

# Generate an embedding
echo "Hello world" | ./embed.sh
```

## Configuration

Set environment variables before starting the service:

| Variable | Default | Description |
|----------|---------|-------------|
| `EMBEDDING_MODEL_ID` | `unsloth/embeddinggemma-300m` | HuggingFace model to use |
| `EMBEDDING_DIMENSION` | `768` | Embedding vector dimension |

Example with a different model:

```bash
EMBEDDING_MODEL_ID=BAAI/bge-small-en-v1.5 ./setup.sh
```

## Usage

### CLI

```bash
# Single string
echo "text to embed" | ./embed.sh

# From a file
cat document.txt | ./embed.sh
```

### API

The service exposes an OpenAI-compatible API on port 8080:

```bash
curl http://localhost:8080/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"model":"unsloth/embeddinggemma-300m","input":"text to embed"}'
```

## Stopping

```bash
docker compose down
```

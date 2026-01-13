#!/bin/bash

# Read input from stdin
input=$(cat)

# Escape the input for JSON (handle quotes and newlines)
escaped_input=$(printf '%s' "$input" | jq -Rs .)

# Call the embeddings API
curl -sf http://localhost:8080/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"${EMBEDDING_MODEL_ID:-unsloth/embeddinggemma-300m}\",\"input\":${escaped_input}}"

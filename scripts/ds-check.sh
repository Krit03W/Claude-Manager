#!/usr/bin/env bash
# ds-check.sh — test the DeepSeek server configured in .env.
# Prints only non-secret info; the API key is never echoed.
set -uo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] || { echo "No .env found in $(pwd)"; exit 1; }
set -a; . ./.env; set +a

base="${DEEPSEEK_BASE_URL%/}"
model="${DS_MODEL_OVERRIDE:-${DEEPSEEK_MODEL:-}}"
auth=()
[[ -n "${DEEPSEEK_API_KEY:-}" ]] && auth=(-H "Authorization: Bearer $DEEPSEEK_API_KEY" -H "x-api-key: $DEEPSEEK_API_KEY")

echo "base url : $base"
echo "model    : ${model:-<empty>}"
echo "api key  : $([[ -n "${DEEPSEEK_API_KEY:-}" ]] && echo "set (${#DEEPSEEK_API_KEY} chars)" || echo "empty")"
echo "format   : ${DEEPSEEK_API_FORMAT:-openai}"
[[ -n "$base" ]] || { echo "DEEPSEEK_BASE_URL is empty"; exit 1; }

# Root without trailing /v1, for the Anthropic-style endpoint.
root="${base%/v1}"

req() { # method url [json]
  local tmp code; tmp="$(mktemp)"
  if [[ $# -ge 3 ]]; then
    code="$(curl -sS -m 120 -o "$tmp" -w '%{http_code}' -X "$1" "$2" ${auth[@]+"${auth[@]}"} \
      -H 'content-type: application/json' -H 'anthropic-version: 2023-06-01' -d "$3" 2>&1)"
  else
    code="$(curl -sS -m 30 -o "$tmp" -w '%{http_code}' "$2" ${auth[@]+"${auth[@]}"} 2>&1)"
  fi
  echo "$code"; head -c 600 "$tmp"; echo; rm -f "$tmp"
}

echo; echo "== 1. GET $base/models (chat models: id, max input tokens)"
curl -sS -m 30 "$base/models" ${auth[@]+"${auth[@]}"} \
  | jq -r '.data[] | select(.mode=="chat" or .mode==null) | "  \(.id)\t\(.max_input_tokens // "-")"' \
  | grep -v -E 'bge|embedding|reranker|whisper'
[[ "${1:-}" == "models" ]] && exit 0

[[ -n "$model" ]] || { echo "DEEPSEEK_MODEL is empty — pick an id from the list above"; exit 1; }

echo; echo "== 2. OpenAI chat: POST $base/chat/completions"
req POST "$base/chat/completions" \
  "{\"model\":\"$model\",\"max_tokens\":20,\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: OK\"}]}"

echo; echo "== 3. Anthropic messages: POST $root/v1/messages"
req POST "$root/v1/messages" \
  "{\"model\":\"$model\",\"max_tokens\":20,\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: OK\"}]}"

#!/usr/bin/env bash

MODEL="${MODEL:-ifioravanti/mistral-grammar-checker:7b}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

USER_INPUT="$*"

# Fallback to prompt if nothing was selected
if [[ -z "$USER_INPUT" ]]; then
  USER_INPUT=$(osascript -e 'Tell application "System Events" to display dialog "Enter text to correct:" default answer ""' -e 'text returned of result' 2>/dev/null)
fi

# Still empty?
if [[ -z "$USER_INPUT" ]]; then
  echo "❌ No input provided." >&2
  exit 1
fi

# Wrap user input in a clear correction instruction
PROMPT="<s><<SYS>>
You are a world-class copy editor. Your job is to correct grammar, spelling, and clarity mistakes in English sentences.
Only return the corrected version of the input sentence, and nothing else — no comments, no explanations, no formatting, no quotations, no annotations.
Keep the original voice and tone. Do not say anything if the input is already correct — just return it exactly as is.

Examples:
Whot is you name?
What is your name?

How old is you?
How old are you?

Wha tme is it?
What time is it?
<</SYS>>

[INST] $USER_INPUT [/INST]"

RESPONSE=$(curl -s -X POST "$OLLAMA_HOST/api/generate" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "model": "$MODEL",
  "prompt": "$PROMPT",
  "stream": false,
  "keep_alive": 60
}
EOF
)

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to connect to Ollama server at $OLLAMA_HOST"
  exit 2
fi

OUTPUT=$(echo "$RESPONSE" | jq -r '.response // "error: invalid response"')

printf "%s" "$OUTPUT"
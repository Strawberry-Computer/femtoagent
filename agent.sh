#!/bin/bash

# Minimal CLI AI Coding Agent: OpenRouter, Claude Sonnet 4, tee exec, permission
# Deps: curl, jq, coreutils

[ -z "$OPENROUTER_API_KEY" ] && { echo "Error: OPENROUTER_API_KEY not set"; exit 1; }
command -v curl >/dev/null || { echo "Error: curl required"; exit 1; }
command -v jq >/dev/null || { echo "Error: jq required"; exit 1; }

ENDPOINT="${ENDPOINT:-https://openrouter.ai/api/v1/chat/completions}"
MODEL="${MODEL:-anthropic/claude-sonnet-4}"
TAIL_LINES="${TAIL_LINES:-500}"
SCRIPT_FILE="${SCRIPT_FILE:-generated_script.sh}"

touch history.txt result.txt
[ -f system_prompt.txt ] || echo "You are a bash coding agent. Generate only the bash script code for the task, no text." > system_prompt.txt

echo "Welcome to AI Coding Agent. Describe task; I'll generate/execute bash. Type 'exit' to quit."

while true; do
    read -e -p "You: " prompt
    [ "$prompt" = "exit" ] && break
    echo "User: $prompt" >> history.txt

    tagged_user="<history-head>$(tail -n "$TAIL_LINES" history.txt | head -n 2)</history-head>
<history-tail>$(tail -n "$TAIL_LINES" history.txt)</history-tail>
<previous-result>$(cat result.txt)</previous-result>
<task>$prompt</task>"

    body=$(jq -n --arg m "$MODEL" --arg s "$(cat system_prompt.txt)" --arg u "$tagged_user" '{model:$m,messages:[{role:"system",content:$s},{role:"user",content:$u}]}')

    response=$(curl -s -X POST "$ENDPOINT" -H "Authorization: Bearer $OPENROUTER_API_KEY" -H "Content-Type: application/json" -d "$body")

    error=$(echo "$response" | jq -r '.error.message // empty')
    [ -n "$error" ] && { echo "Error: $error"; continue; }

    script=$(echo "$response" | jq -r '.choices[0].message.content // "No script generated"')
    echo "Generated Script:\n$script" >> history.txt
    echo "AI Generated Script: $script"

    [ "$script" = "No script generated" ] && continue
    echo "$script" > "$SCRIPT_FILE"

    read -e -p "Execute this script? (y/n): " confirm
    [[ "$confirm" =~ ^[yY]$ ]] && bash "$SCRIPT_FILE" 2>&1 | tee result.txt
done

echo "Goodbye!"

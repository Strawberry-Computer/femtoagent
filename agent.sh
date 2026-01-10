#!/bin/bash

# Minimal CLI AI Coding Agent: OpenRouter, Claude Sonnet 4, tool-call based
# Deps: curl, jq, coreutils

[ -z "$OPENROUTER_API_KEY" ] && { echo "Error: OPENROUTER_API_KEY not set"; exit 1; }
command -v curl >/dev/null || { echo "Error: curl required"; exit 1; }
command -v jq >/dev/null || { echo "Error: jq required"; exit 1; }

ENDPOINT="${ENDPOINT:-https://openrouter.ai/api/v1/chat/completions}"
MODEL="${MODEL:-anthropic/claude-opus-4.5}"

[ -f history.json ] || echo "[]" > history.json
touch result.txt
[ -f system_prompt.txt ] || echo "You are a bash coding agent. Use the run_script tool to execute bash commands." > system_prompt.txt

TOOLS='[{"type":"function","function":{"name":"run_script","description":"Execute bash script","parameters":{"type":"object","properties":{"script":{"type":"string"}},"required":["script"]}}}]'

append_hist() { jq --arg u "$1" --arg a "$2" '. + [{role:"user",content:$u},{role:"assistant",content:$a}]' history.json > history.json.tmp && mv history.json.tmp history.json; }

echo "AI Coding Agent v2. Type 'exit' to quit."

while true; do
    read -e -p "You: " prompt
    [[ "$prompt" = "exit" ]] && break
    [[ -z "$prompt" ]] && continue

    result=$(<result.txt)
    [[ -n "$result" ]] && user="<previous-result>$result</previous-result>
<task>$prompt</task>" || user="<task>$prompt</task>"

    messages=$(jq -n --arg sys "$(<system_prompt.txt)" --slurpfile h history.json --arg u "$user" '
        [{role:"system",content:$sys,cache_control:{type:"ephemeral"}}] +
        (if ($h[0]|length)>0 then $h[0][:-1]+[$h[0][-1]+{cache_control:{type:"ephemeral"}}] else [] end) +
        [{role:"user",content:$u}]')

    resp=$(curl -s "$ENDPOINT" -H "Authorization: Bearer $OPENROUTER_API_KEY" -H "Content-Type: application/json" \
        -d "$(jq -nc --arg m "$MODEL" --argjson msg "$messages" --argjson t "$TOOLS" '{model:$m,messages:$msg,tools:$t}')")

    err=$(echo "$resp" | jq -r '.error.message // empty')
    [[ -n "$err" ]] && { echo "Error: $err"; continue; }

    script=$(echo "$resp" | jq -r '.choices[0].message.tool_calls[0].function.arguments | fromjson | .script // empty')

    if [[ -n "$script" ]]; then
        echo "Script: $script"
        append_hist "$user" "$script"
        read -e -p "Run? (y/n): " c
        [[ "$AUTO" = "1" || "$c" =~ ^[yY]$ ]] && bash -c "$script" 2>&1 | tee result.txt
    else
        txt=$(echo "$resp" | jq -r '.choices[0].message.content // "No response"')
        echo "AI: $txt"
        append_hist "$user" "$txt"
    fi
done
echo "Goodbye!"

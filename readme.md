# FemtoAgent: Minimal CLI AI Coding Assistant

A lightweight bash-based AI coding agent that uses the OpenRouter API to generate and execute bash scripts.

## How It Works

1. Takes user input as task descriptions in natural language
2. Maintains conversation history in history.txt (latest 500 lines)
3. Structures context with XML-like tags:
   - <history-head> - Start of history
   - <history-tail> - Recent conversation 
   - <previous-result> - Last command output
   - <task> - Current user request
4. Makes API call to OpenRouter using Claude 3.5 Sonnet
5. Extracts bash script from AI response
6. Allows user to review and execute generated script
7. Captures command output in result.txt

## Usage

1. Set your OpenRouter API key:
```
export OPENROUTER_API_KEY="your-key"
```

2. Run the agent:
```
bash agent.sh
```

3. Describe what you want to do in plain English
4. Review and confirm script execution with y/n

## Requirements

- curl 
- jq
- coreutils

## Configuration

Environment variables:
- OPENROUTER_API_KEY (required)
- MODEL (default: anthropic/claude-3.5-sonnet) 
- ENDPOINT (default: https://openrouter.ai/api/v1/chat/completions)
- TAIL_LINES (default: 500)
- SCRIPT_FILE (default: generated_script.sh)

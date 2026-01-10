# FemtoAgent: Minimal CLI AI Coding Assistant

A lightweight bash-based AI coding agent that uses the OpenRouter API with native tool calls.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         agent.sh                             │
│                   Tool-Call Based CLI Agent                     │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │   User Input     │
    │   "You: ___"     │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────────────────────────────────────┐
    │  Build context:                                  │
    │  • System prompt (cached)                        │
    │  • Conversation history (cached)                 │
    │  • <previous-result> + <task> tags               │
    └────────────────────┬─────────────────────────────┘
                         │
                         ▼
    ┌─────────────┐         ┌─────────────────┐
    │  agent   │──curl──▶│  OpenRouter API │
    │             │◀────────│  (Claude Model) │
    └─────────────┘         └─────────────────┘
                         │
           ┌─────────────┴─────────────┐
           ▼                           ▼
    ┌──────────────┐           ┌───────────────┐
    │  Tool Call   │           │  Text Reply   │
    │  run_script  │           │  (no tool)    │
    └──────┬───────┘           └───────────────┘
           │
           ▼
    ┌──────────────────┐
    │ Show script      │
    │ Ask "Run? (y/n)" │
    └────────┬─────────┘
             │ (confirmed)
             ▼
    ┌──────────────────────────────────────────────────┐
    │  bash -c "$script" ──┬──▶ stdout                 │
    │                      └──▶ result.txt (for next)  │
    └──────────────────────────────────────────────────┘
```

## Files

```
├── agent.sh        # Main agent script
├── history.json       # Conversation memory [{role,content},...]
├── result.txt         # Last script output (fed back to AI)
└── system_prompt.txt  # Customizable system instructions
```

## Usage

1. Set your OpenRouter API key:
```bash
export OPENROUTER_API_KEY="your-key"
```

2. Run the agent:
```bash
bash agent.sh
```

3. Describe tasks in plain English
4. Review and confirm script execution with y/n

### Auto-execute mode
```bash
AUTO=1 bash agent.sh
```

## Requirements

- curl 
- jq
- coreutils

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| OPENROUTER_API_KEY | (required) | Your OpenRouter API key |
| MODEL | anthropic/claude-sonnet-4-20250514 | Model to use |
| ENDPOINT | https://openrouter.ai/api/v1/chat/completions | API endpoint |
| AUTO | 0 | Set to 1 to auto-execute scripts |

## How It Works

1. User describes a task in natural language
2. Agent builds messages with system prompt + history + current task
3. Sends request to OpenRouter with `run_script` tool definition
4. AI responds with either:
   - **Tool call**: Script to execute (user confirms, output saved)
   - **Text**: Direct response (displayed to user)
5. History and results persist for multi-turn conversations
6. Prompt caching reduces API costs on repeated context

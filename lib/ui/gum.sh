#!/bin/bash

# UI wrapper module for gum TUI tool with non-interactive fallbacks
# Provides styled output and interactive prompts with graceful degradation

source "$(dirname "${BASH_SOURCE[0]}")/../core/detect.sh"

# Text input with fallback to default or environment variable
# Args: prompt, placeholder, default, env_var
ui_input() {
    local prompt="$1"
    local placeholder="$2"
    local default="$3"
    local env_var="$4"
    
    # Check for environment variable override
    if [[ -n "$env_var" && -n "${!env_var:-}" ]]; then
        echo "${!env_var}"
        return 0
    fi
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum input --placeholder "$placeholder" --value "$default" --prompt "$prompt "
    else
        # Non-interactive: use default or fail
        if [[ -n "$default" ]]; then
            echo "$default"
        else
            echo "Error: $prompt required (set $env_var)" >&2
            return 1
        fi
    fi
}

# Selection from options with fallback to first option
# Args: header, options...
ui_choose() {
    local header="$1"
    shift
    local options=("$@")
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum choose "${options[@]}" --header "$header"
    else
        # Non-interactive: return first option
        if [[ ${#options[@]} -gt 0 ]]; then
            echo "${options[0]}"
        else
            echo "Error: No options provided for $header" >&2
            return 1
        fi
    fi
}

# Yes/no confirmation with fallback to default
# Args: question, default (true/false)
ui_confirm() {
    local question="$1"
    local default="$2"
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum confirm "$question"
    else
        # Non-interactive: use default
        if [[ "$default" == "true" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Spinner with command execution and fallback to silent execution
# Args: title, command
ui_spin() {
    local title="$1"
    local command="$2"
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum spin --spinner dot --title "$title" -- bash -c "$command"
    else
        # Non-interactive: execute silently
        bash -c "$command"
    fi
}

# Styled text output with fallback to plain text
# Args: text, style...
ui_style() {
    local text="$1"
    shift
    local styles=("$@")
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum style "${styles[@]}" "$text"
    else
        # Non-interactive: output plain text
        echo "$text"
    fi
}

# Formatted header output
# Args: text
ui_header() {
    local text="$1"
    
    # Check if interactive and gum is available
    if is_interactive && command -v gum &>/dev/null; then
        gum style --foreground 212 --bold "$text"
    else
        # Non-interactive: output with simple formatting
        echo "=== $text ==="
    fi
}

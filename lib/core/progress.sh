#!/bin/bash
# Progress tracking module for resume capability
# Stores progress in ~/.openboot/progress.json

export PROGRESS_FILE="${HOME}/.openboot/progress.json"

# Initialize progress file
progress_init() {
    mkdir -p "$(dirname "$PROGRESS_FILE")"
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo '{"steps":{},"last_step":""}' > "$PROGRESS_FILE"
    fi
}

# Mark step as in-progress
progress_start() {
    local step="$1"
    
    if command -v jq &>/dev/null; then
        jq --arg s "$step" '.steps[$s] = "in_progress" | .last_step = $s' "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
    else
        # Fallback: simple sed-based update
        local content
        content=$(cat "$PROGRESS_FILE")
        # Remove old entry if exists, add new one
        content=$(echo "$content" | sed "s/\"$step\":\"[^\"]*\"//" | sed 's/,}/}/' | sed 's/,]/]/')
        # Insert new entry before closing brace
        content=$(echo "$content" | sed "s/\"last_step\":\"[^\"]*\"/\"last_step\":\"$step\"/" | sed "s/\"steps\":{/\"steps\":{\"$step\":\"in_progress\",/")
        echo "$content" > "$PROGRESS_FILE"
    fi
}

# Mark step as complete
progress_complete() {
    local step="$1"
    
    if command -v jq &>/dev/null; then
        jq --arg s "$step" '.steps[$s] = "complete"' "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
    else
        # Fallback: simple sed-based update
        local content
        content=$(cat "$PROGRESS_FILE")
        content=$(echo "$content" | sed "s/\"$step\":\"in_progress\"/\"$step\":\"complete\"/")
        echo "$content" > "$PROGRESS_FILE"
    fi
}

# Check if step is complete (returns 0 if complete, 1 if not)
progress_is_complete() {
    local step="$1"
    local step_status
    
    if command -v jq &>/dev/null; then
        step_status=$(jq -r --arg s "$step" '.steps[$s] // ""' "$PROGRESS_FILE")
        [[ "$step_status" == "complete" ]]
    else
        # Fallback: grep-based check
        grep -q "\"$step\":\"complete\"" "$PROGRESS_FILE"
    fi
}

# Get last incomplete step
progress_get_last() {
    if command -v jq &>/dev/null; then
        jq -r '.last_step // ""' "$PROGRESS_FILE"
    else
        # Fallback: grep-based extraction
        grep -o '"last_step":"[^"]*"' "$PROGRESS_FILE" | cut -d'"' -f4
    fi
}

# Reset progress (clear all steps)
progress_reset() {
    echo '{"steps":{},"last_step":""}' > "$PROGRESS_FILE"
}

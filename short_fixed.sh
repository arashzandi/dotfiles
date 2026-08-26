#!/bin/bash
# Wrapper script for Shortcut CLI that fixes comment posting and adds file upload support
# Uses the working `short api` command under the hood

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  search [query]           Search stories (passes through to 'short search')
  <story_id> comment <text>           Post a comment to a story
  <story_id> state <state_id_or_name>  Update story workflow state
  <story_id> upload <file_path>        Upload a file to a story

Examples:
  $0 search "donation credits"
  $0 78359 comment "This is a test comment"
  $0 78359 state "In Progress"
  $0 78359 upload /path/to/file.pdf
EOF
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1
shift

# Handle search command (doesn't need story_id)
if [ "$COMMAND" = "search" ]; then
    short search "$@"
    exit $?
fi

# All other commands require story_id
if [ $# -lt 2 ]; then
    usage
fi

STORY_ID=$COMMAND
COMMAND=$1
shift

case "$COMMAND" in
    comment)
        if [ -z "${1:-}" ]; then
            echo "Error: Comment text is required" >&2
            exit 1
        fi
        COMMENT_TEXT="$1"
        echo "Posting comment to story $STORY_ID..."
        short api "/stories/$STORY_ID/comments" -X POST \
            -H "Content-Type: application/json" \
            -f "text=$COMMENT_TEXT" | jq -r '.app_url // "Comment posted successfully"'
        ;;
    
    state)
        if [ -z "${1:-}" ]; then
            echo "Error: State ID or name is required" >&2
            exit 1
        fi
        STATE="$1"
        
        # Check if STATE is a numeric ID (starts with digits)
        if [[ "$STATE" =~ ^[0-9]+$ ]]; then
            STATE_ID="$STATE"
        else
            # Try to look up state ID by name
            echo "Looking up state ID for: $STATE"
            # Get workflows and find matching state
            STATE_ID=$(short workflows 2>/dev/null | grep -i "$STATE" | head -1 | grep -oE '#[0-9]+' | tr -d '#' || echo "")
            
            if [ -z "$STATE_ID" ]; then
                echo "Warning: Could not find state ID for '$STATE'. Trying to use as-is..." >&2
                STATE_ID="$STATE"
            else
                echo "Found state ID: $STATE_ID"
            fi
        fi
        
        echo "Updating story $STORY_ID state to: $STATE_ID"
        short api "/stories/$STORY_ID" -X PUT \
            -H "Content-Type: application/json" \
            -f "workflow_state_id=$STATE_ID" | jq -r '.app_url // "State updated successfully"'
        ;;
    
    upload)
        if [ -z "${1:-}" ]; then
            echo "Error: File path is required" >&2
            exit 1
        fi
        FILE_PATH="$1"
        if [ ! -f "$FILE_PATH" ]; then
            echo "Error: File not found: $FILE_PATH" >&2
            exit 1
        fi
        
        echo "Uploading file to story $STORY_ID..."
        # Get the API token from short CLI config
        # Shortcut API requires: POST /api/v3/files with multipart/form-data
        # Then POST /api/v3/stories/{story-id}/files with file_id
        
        # For now, we'll use curl directly since short api doesn't support file uploads well
        # First, we need to get the API token
        TOKEN_FILE="$HOME/.shortcutrc"
        if [ ! -f "$TOKEN_FILE" ]; then
            TOKEN_FILE="$HOME/.config/shortcut/config.json"
        fi
        
        if [ -f "$TOKEN_FILE" ]; then
            TOKEN=$(jq -r '.token // .apiToken // empty' "$TOKEN_FILE" 2>/dev/null || echo "")
        fi
        
        if [ -z "${TOKEN:-}" ] && [ -n "${SHORTCUT_API_TOKEN:-}" ]; then
            TOKEN="$SHORTCUT_API_TOKEN"
        fi
        
        if [ -z "${TOKEN:-}" ]; then
            echo "Error: Could not find Shortcut API token. Please set SHORTCUT_API_TOKEN environment variable or configure short CLI." >&2
            exit 1
        fi
        
        # Upload the file
        echo "Uploading file..."
        UPLOAD_RESPONSE=$(curl -s -X POST \
            "https://api.app.shortcut.com/api/v3/files" \
            -H "Shortcut-Token: $TOKEN" \
            -F "file=@$FILE_PATH")
        
        FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.id // empty')
        
        if [ -z "$FILE_ID" ] || [ "$FILE_ID" = "null" ]; then
            echo "Error: Failed to upload file. Response: $UPLOAD_RESPONSE" >&2
            exit 1
        fi
        
        echo "File uploaded with ID: $FILE_ID"
        echo "Attaching to story..."
        
        # Attach the file to the story
        short api "/stories/$STORY_ID/files" -X POST \
            -H "Content-Type: application/json" \
            -f "file_id=$FILE_ID" | jq -r '.app_url // "File attached successfully"'
        ;;
    
    *)
        echo "Error: Unknown command: $COMMAND" >&2
        usage
        ;;
esac


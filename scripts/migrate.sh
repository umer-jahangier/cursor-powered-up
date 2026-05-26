#!/bin/bash

# =============================================================================
# GSD Migration Script: Claude Code → Cursor IDE
# =============================================================================
#
# This script automates the conversion of GSD files from the original Claude Code
# format to the Cursor IDE format. It handles:
# - Path reference updates (~/.claude/ → ~/.cursor/)
# - Command name format changes (gsd:cmd → gsd-cmd)
# - Tool name conversions (PascalCase → snake_case)
# - Frontmatter format changes (allowed-tools array → tools object)
# - Color name to hex conversions
#
# Usage:
#   ./migrate.sh --source /path/to/gsd-master [--output ./src] [--dry-run]
#
# =============================================================================

set -e

# Default values
OUTPUT_PATH="./src"
DRY_RUN=false
SOURCE_PATH=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source|-s)
            SOURCE_PATH="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 --source <path> [--output <path>] [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --source, -s    Path to GSD master repository (required)"
            echo "  --output, -o    Output path for converted files (default: ./src)"
            echo "  --dry-run, -n   Show what would be changed without making changes"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate source path
if [ -z "$SOURCE_PATH" ]; then
    echo -e "${RED}ERROR: --source is required${NC}"
    echo "Usage: $0 --source <path> [--output <path>] [--dry-run]"
    exit 1
fi

if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}ERROR: Source path not found: $SOURCE_PATH${NC}"
    exit 1
fi

# Logging functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_change() {
    echo -e "${YELLOW}[CHANGE]${NC} $1"
}

log_skip() {
    echo -e "${GRAY}[SKIP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Statistics
CONVERTED=0
COPIED=0
ERRORS=0

# Tool name mapping function
map_tool_name() {
    local tool="$1"
    case "$tool" in
        "Read") echo "read" ;;
        "Write") echo "write" ;;
        "Edit") echo "edit" ;;
        "Bash") echo "bash" ;;
        "Glob") echo "glob" ;;
        "Grep") echo "grep" ;;
        "Task") echo "" ;;  # Removed - handled differently
        "AskUserQuestion") echo "ask_question" ;;
        "TodoWrite") echo "todo_write" ;;
        "WebFetch") echo "web_fetch" ;;
        "WebSearch") echo "web_search" ;;
        "MultiEdit") echo "multi_edit" ;;
        *) echo "" ;;
    esac
}

# Convert command frontmatter (allowed-tools array to tools object)
convert_command_frontmatter() {
    local content="$1"
    
    # Check if file has allowed-tools in frontmatter
    if echo "$content" | grep -q "allowed-tools:"; then
        # Extract the frontmatter
        local frontmatter
        frontmatter=$(echo "$content" | sed -n '/^---$/,/^---$/p' | head -n -1 | tail -n +2)
        
        # Extract tools from allowed-tools block
        local tools_block
        tools_block=$(echo "$frontmatter" | sed -n '/allowed-tools:/,/^[a-z]/p' | grep "^\s*-" || true)
        
        if [ -n "$tools_block" ]; then
            # Build new tools object
            local new_tools="tools:"
            while IFS= read -r line; do
                local tool
                tool=$(echo "$line" | sed 's/.*-\s*//' | tr -d '[:space:]')
                local mapped
                mapped=$(map_tool_name "$tool")
                if [ -n "$mapped" ]; then
                    new_tools="$new_tools\n  $mapped: true"
                fi
            done <<< "$tools_block"
            
            # Replace allowed-tools block with tools object
            # This is a simplified replacement - removes allowed-tools and adds tools
            content=$(echo "$content" | sed '/allowed-tools:/,/^[a-z]/{ /allowed-tools:/d; /^\s*-/d; }')
            content=$(echo "$content" | sed "s/^---$/---\n${new_tools}/")
        fi
    fi
    
    echo "$content"
}

# Convert agent frontmatter (comma-separated tools to tools object)
convert_agent_frontmatter() {
    local content="$1"
    
    # Check if file has comma-separated tools line (agent style)
    local tools_line
    tools_line=$(echo "$content" | grep -E "^tools:\s*[A-Z]" || true)
    
    if [ -n "$tools_line" ]; then
        # Extract tool names
        local tools_str
        tools_str=$(echo "$tools_line" | sed 's/tools:\s*//')
        
        # Build new tools object
        local new_tools="tools:"
        IFS=',' read -ra tools_array <<< "$tools_str"
        for tool in "${tools_array[@]}"; do
            tool=$(echo "$tool" | tr -d '[:space:]')
            local mapped
            mapped=$(map_tool_name "$tool")
            if [ -n "$mapped" ]; then
                new_tools="$new_tools\n  $mapped: true"
            fi
        done
        
        # Replace the tools line
        content=$(echo "$content" | sed "s/^tools:.*/$new_tools/")
    fi
    
    echo "$content"
}

# Convert a single file
convert_file() {
    local src="$1"
    local dest="$2"
    local file_type="$3"
    
    local content
    content=$(cat "$src")
    local original_content="$content"
    
    # Path references
    content=$(echo "$content" | sed 's|~/.claude/|~/.cursor/|g')
    content=$(echo "$content" | sed 's|\.claude/|.cursor/|g')
    content=$(echo "$content" | sed 's|@~/.claude/get-shit-done/|@~/.cursor/get-shit-done/|g')
    content=$(echo "$content" | sed 's|\$CLAUDE_PROJECT_DIR|\${workspaceFolder}|g')
    
    # Command references
    content=$(echo "$content" | sed 's|/gsd:|/gsd-|g')
    content=$(echo "$content" | sed 's|name: gsd:|name: gsd-|g')
    
    # Color conversions
    content=$(echo "$content" | sed 's|color: cyan|color: "#00FFFF"|g')
    content=$(echo "$content" | sed 's|color: red|color: "#FF0000"|g')
    content=$(echo "$content" | sed 's|color: green|color: "#00FF00"|g')
    content=$(echo "$content" | sed 's|color: blue|color: "#0000FF"|g')
    content=$(echo "$content" | sed 's|color: yellow|color: "#FFFF00"|g')
    content=$(echo "$content" | sed 's|color: magenta|color: "#FF00FF"|g')
    content=$(echo "$content" | sed 's|color: orange|color: "#FFA500"|g')
    content=$(echo "$content" | sed 's|color: purple|color: "#800080"|g')
    content=$(echo "$content" | sed 's|color: pink|color: "#FFC0CB"|g')
    content=$(echo "$content" | sed 's|color: white|color: "#FFFFFF"|g')
    content=$(echo "$content" | sed 's|color: gray|color: "#808080"|g')
    content=$(echo "$content" | sed 's|color: grey|color: "#808080"|g')
    
    # Frontmatter conversion based on file type
    if [ "$file_type" = "command" ]; then
        content=$(convert_command_frontmatter "$content")
    elif [ "$file_type" = "agent" ]; then
        content=$(convert_agent_frontmatter "$content")
    fi
    
    # Tool names in prose (for non-frontmatter content in workflows, templates, references)
    if [ "$file_type" != "command" ] && [ "$file_type" != "agent" ]; then
        content=$(echo "$content" | sed 's|\bRead\b|read|g')
        content=$(echo "$content" | sed 's|\bWrite\b|write|g')
        content=$(echo "$content" | sed 's|\bEdit\b|edit|g')
        content=$(echo "$content" | sed 's|\bBash\b|bash|g')
        content=$(echo "$content" | sed 's|\bGlob\b|glob|g')
        content=$(echo "$content" | sed 's|\bGrep\b|grep|g')
        content=$(echo "$content" | sed 's|\bAskUserQuestion\b|ask_question|g')
        content=$(echo "$content" | sed 's|\bTodoWrite\b|todo_write|g')
        content=$(echo "$content" | sed 's|\bWebFetch\b|web_fetch|g')
        content=$(echo "$content" | sed 's|\bWebSearch\b|web_search|g')
        content=$(echo "$content" | sed 's|\bMultiEdit\b|multi_edit|g')
    fi
    
    # Check if content changed
    if [ "$content" != "$original_content" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_change "Would convert: $src → $dest"
        else
            mkdir -p "$(dirname "$dest")"
            echo "$content" > "$dest"
            log_change "Converted: $src → $dest"
        fi
        return 0
    else
        if [ "$DRY_RUN" = true ]; then
            log_skip "No changes needed: $src"
        else
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            log_info "Copied unchanged: $src → $dest"
        fi
        return 1
    fi
}

# Main migration
main() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  GSD Migration: Claude Code → Cursor${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${MAGENTA}DRY RUN MODE - No files will be modified${NC}"
        echo ""
    fi
    
    # Process commands
    log_info "Processing commands..."
    if [ -d "$SOURCE_PATH/commands/gsd" ]; then
        for file in "$SOURCE_PATH/commands/gsd"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                dest="$OUTPUT_PATH/commands/gsd/$filename"
                if convert_file "$file" "$dest" "command"; then
                    ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
                else
                    ((COPIED++)) || COPIED=$((COPIED + 1))
                fi
            fi
        done
    fi
    
    # Process agents
    log_info ""
    log_info "Processing agents..."
    if [ -d "$SOURCE_PATH/agents" ]; then
        for file in "$SOURCE_PATH/agents"/gsd-*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                dest="$OUTPUT_PATH/agents/$filename"
                if convert_file "$file" "$dest" "agent"; then
                    ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
                else
                    ((COPIED++)) || COPIED=$((COPIED + 1))
                fi
            fi
        done
    fi
    
    # Process workflows
    log_info ""
    log_info "Processing workflows..."
    if [ -d "$SOURCE_PATH/get-shit-done/workflows" ]; then
        for file in "$SOURCE_PATH/get-shit-done/workflows"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                dest="$OUTPUT_PATH/workflows/$filename"
                if convert_file "$file" "$dest" "workflow"; then
                    ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
                else
                    ((COPIED++)) || COPIED=$((COPIED + 1))
                fi
            fi
        done
    fi
    
    # Process templates
    log_info ""
    log_info "Processing templates..."
    if [ -d "$SOURCE_PATH/get-shit-done/templates" ]; then
        find "$SOURCE_PATH/get-shit-done/templates" -type f | while read -r file; do
            relative_path="${file#$SOURCE_PATH/get-shit-done/templates/}"
            dest="$OUTPUT_PATH/templates/$relative_path"
            if convert_file "$file" "$dest" "template"; then
                ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
            else
                ((COPIED++)) || COPIED=$((COPIED + 1))
            fi
        done
    fi
    
    # Process references
    log_info ""
    log_info "Processing references..."
    if [ -d "$SOURCE_PATH/get-shit-done/references" ]; then
        for file in "$SOURCE_PATH/get-shit-done/references"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                dest="$OUTPUT_PATH/references/$filename"
                if convert_file "$file" "$dest" "reference"; then
                    ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
                else
                    ((COPIED++)) || COPIED=$((COPIED + 1))
                fi
            fi
        done
    fi
    
    # Process hooks
    log_info ""
    log_info "Processing hooks..."
    if [ -d "$SOURCE_PATH/hooks" ]; then
        for file in "$SOURCE_PATH/hooks"/gsd-*.js; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                dest="$OUTPUT_PATH/hooks/$filename"
                if convert_file "$file" "$dest" "hook"; then
                    ((CONVERTED++)) || CONVERTED=$((CONVERTED + 1))
                else
                    ((COPIED++)) || COPIED=$((COPIED + 1))
                fi
            fi
        done
    fi
    
    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Migration Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "  Converted: ${YELLOW}$CONVERTED${NC}"
    echo -e "  Copied:    ${CYAN}$COPIED${NC}"
    echo -e "  Errors:    $([ $ERRORS -gt 0 ] && echo -e "${RED}$ERRORS${NC}" || echo -e "${GREEN}$ERRORS${NC}")"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${MAGENTA}This was a DRY RUN. Run without --dry-run to apply changes.${NC}"
        echo ""
    else
        echo -e "${GREEN}Migration complete! Review changes and run verification.${NC}"
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  1. Review converted files in: $OUTPUT_PATH"
        echo "  2. Run verification: grep -r '.claude' $OUTPUT_PATH --include='*.md'"
        echo "  3. Test installation: ./install.sh"
    fi
}

main

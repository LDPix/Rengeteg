#!/usr/bin/env bash

set -e

# =========================================
# Config
# =========================================

GODOT_BIN=${GODOT_BIN:-godot}
PROJECT_PATH="."

# =========================================
# Helpers
# =========================================

print_help() {
    echo "Usage: ./run_godot.sh [command]"
    echo ""
    echo "Commands:"
    echo "  editor     Open Godot editor"
    echo "  run        Run the game"
    echo "  debug      Run with debug output"
    echo "  headless   Run headless check (CI / Codex)"
    echo "  test       Alias for headless"
    echo ""
    echo "Env:"
    echo "  GODOT_BIN=path/to/godot"
}

# =========================================
# Commands
# =========================================

cmd_editor() {
    echo "Launching Godot editor..."
    $GODOT_BIN --path "$PROJECT_PATH" -e
}

cmd_run() {
    echo "Running project..."
    $GODOT_BIN --path "$PROJECT_PATH"
}

cmd_debug() {
    echo "Running project with debug output..."
    $GODOT_BIN --path "$PROJECT_PATH" -d
}

cmd_headless() {
    echo "Running headless validation..."

    # This:
    # - loads the project
    # - initializes resources
    # - exits immediately
    #
    # Good for CI sanity checks
    local temp_home
    temp_home="${TMPDIR:-/tmp}"

    HOME="$temp_home" \
    XDG_DATA_HOME="$temp_home" \
    XDG_CONFIG_HOME="$temp_home" \
    $GODOT_BIN --path "$PROJECT_PATH" --headless --quit || {
        echo "❌ Headless run failed"
        exit 1
    }

    echo "✅ Headless check passed"
}

# =========================================
# Entry point
# =========================================

case "$1" in
    editor)
        cmd_editor
        ;;
    run)
        cmd_run
        ;;
    debug)
        cmd_debug
        ;;
    headless|test)
        cmd_headless
        ;;
    *)
        print_help
        ;;
esac

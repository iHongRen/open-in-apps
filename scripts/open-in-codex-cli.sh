#!/bin/bash

CLI_CMD="${CLI_COMMAND:-codex}"
CONFIG_FILE="$HOME/.openin/config"  #YAML 
CONFIG_KEY="OPEN_IN_CODEX_CLI_TERM"

# ─── Shell Detection ─────────────────────────────────────────────────────────

get_shell() {
    if [ -n "$SHELL" ] && [ -x "$SHELL" ]; then
        echo "$SHELL"
    elif [ -x /bin/zsh ]; then
        echo "/bin/zsh"
    else
        echo "/bin/bash"
    fi
}

SHELL_BIN="$(get_shell)"


# ─── Terminal Launchers (run_xx style) ──────────────────────────────────────
run_ghostty() {
    local dir="$1"
    shell_cmd="cd $(printf '%q' "$dir") && $CLI_CMD"
    open -na "Ghostty" --args --initial-command="$SHELL_BIN -lc $(printf '%q' "$shell_cmd")" 2>/dev/null 
}

run_iterm() {
    local dir="$1"
    (
        osascript - "$dir" "$CLI_CMD" <<'APPLESCRIPT'
on run argv
    set cmd to ("cd " & quoted form of (item 1 of argv) & " && " & (item 2 of argv))
    tell application "iTerm"
        activate
        if (count of windows) = 0 then
            create window with default profile
        end if
        tell current window
            create tab with default profile
            tell current session
                write text cmd
            end tell
        end tell
    end tell
end run
APPLESCRIPT
    ) &
}


run_terminal() {
    local dir="$1"
    (
        osascript - "$dir" "$CLI_CMD" <<'APPLESCRIPT'
on run argv
    tell application "Terminal"
        activate
        do script ("cd " & quoted form of (item 1 of argv) & " && " & (item 2 of argv))
    end tell
end run
APPLESCRIPT
    ) &
}

run_kitty() {
    local dir="$1"
    local path="/Applications/kitty.app/Contents/MacOS/kitty"
    
    if [ -x "$path" ]; then
        "$path" \
            --directory "$dir" $SHELL_BIN -lc "cd $(printf '%q' "$dir") && $CLI_CMD" &>/dev/null &
        return
    fi
    run_terminal "$dir"
}

run_wezterm() {
    local dir="$1"
    local path="/Applications/WezTerm.app/Contents/MacOS/wezterm"
    
    if [ -x "$path" ]; then
        "$path" start \
            --always-new-process \
            --cwd "$dir" \
            -- $SHELL_BIN -lc "cd $(printf '%q' "$dir") && $CLI_CMD" &>/dev/null &
        return
    fi
    
    run_terminal "$dir"
}


run_alacritty() {
    local dir="$1"
    local path="/Applications/Alacritty.app/Contents/MacOS/alacritty"
    
    if [ -x "$path" ]; then
        "$path" \
            --working-directory "$dir" -e $SHELL_BIN -lc "cd $(printf '%q' "$dir") && $CLI_CMD" &>/dev/null &
        return
    fi
    
    run_terminal "$dir"
}


# ─── Main Dispatch ───────────────────────────────────────────────────────────

open_in_terminal() {
    local dir="$1"
    n=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
    case "$n" in
        *ghostty*)    run_ghostty "$dir" ;;
        *iterm*)      run_iterm "$dir" ;;
        *wezterm*)    run_wezterm "$dir" ;;
        *alacritty*)  run_alacritty "$dir" ;;
        *kitty*)      run_kitty "$dir" ;;
        *)            run_terminal "$dir" ;;
    esac
}

# ─── Terminal Detection ──────────────────────────────────────────────────────

get_default_terminal() {
    local bundle_id
    bundle_id=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
        | awk '/LSHandlerContentType.*public.shell-script/{found=1} found && /LSHandlerRoleAll/ && $0 !~ /LSHandlerRoleAll = "-"/{gsub(/"/,"",$3); gsub(/;/,"",$3); print $3; exit}')

    if [ -n "$bundle_id" ] && [ "$bundle_id" != "-" ]; then
        mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" 2>/dev/null | head -n1
    fi
}

get_term() {
    local term_value=""

    if [ -f "$CONFIG_FILE" ]; then
        if command -v yq >/dev/null 2>&1; then
            term_value=$(yq e ".$CONFIG_KEY // \"\"" "$CONFIG_FILE" 2>/dev/null)
        else
            # Fallback: simple grep for basic YAML
            term_value=$(grep "^$CONFIG_KEY:" "$CONFIG_FILE" | sed "s/^$CONFIG_KEY:\s*//" | sed 's/^"//' | sed 's/"$//')
        fi
    fi

    if [ -n "$term_value" ]; then
        echo "$term_value"
    else
        get_default_terminal
    fi
}

# ─── Entry Point ─────────────────────────────────────────────────────────────

term="$(get_term)"
# term="wezterm"
# term="alacritty"
# term="kitty"
# term="iterm"
# term="terminal"
# term="ghostty"

for f in "$@"; do
    if [ -d "$f" ]; then
        abs_dir="$(cd "$f" && pwd)"
    elif [ -f "$f" ]; then
        abs_dir="$(cd "$(dirname -- "$f")" && pwd)"
    else
        continue
    fi
    open_in_terminal "$abs_dir" "$term"
done

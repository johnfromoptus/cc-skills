#!/bin/bash
# Single line: Model | dir@branch (+/-) | tokens/ctx (%) | effort | in out cache | $cost

set -f  # disable globbing

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ANSI colors matching oh-my-posh theme
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

# Format token counts (e.g., 50k / 200k)
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# Format number with commas (e.g., 134,938)
format_commas() {
    printf "%'d" "$1"
}

# Return color escape based on usage percentage
# Usage: usage_color <pct>
usage_color() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then echo "$red"
    elif [ "$pct" -ge 70 ]; then echo "$orange"
    elif [ "$pct" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# ===== Extract data from JSON =====
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# Context window
size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

# Token usage
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Session-cumulative tokens
session_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
session_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

if [ "$size" -gt 0 ]; then
    pct_used=$(( current * 100 / size ))
else
    pct_used=0
fi
pct_remain=$(( 100 - pct_used ))

used_comma=$(format_commas $current)
remain_comma=$(format_commas $(( size - current )))

# Check reasoning effort
settings_path="$HOME/.claude/settings.json"
effort_level="medium"
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
    effort_level="$CLAUDE_CODE_EFFORT_LEVEL"
elif [ -f "$settings_path" ]; then
    effort_val=$(jq -r '.effortLevel // empty' "$settings_path" 2>/dev/null)
    [ -n "$effort_val" ] && effort_level="$effort_val"
fi

# ===== Build single-line output =====
out=""
out+="${blue}${model_name}${reset}"

# Current working directory
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
    display_dir="${cwd##*/}"
    git_branch=$(git -C "${cwd}" rev-parse --abbrev-ref HEAD 2>/dev/null)
    out+=" ${dim}|${reset} "
    out+="${cyan}${display_dir}${reset}"
    if [ -n "$git_branch" ]; then
        out+="${dim}@${reset}${green}${git_branch}${reset}"
        git_stat=$(git -C "${cwd}" diff --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        [ -n "$git_stat" ] && out+=" ${dim}(${reset}${green}${git_stat%% *}${reset} ${red}${git_stat##* }${reset}${dim})${reset}"
    fi
fi

out+=" ${dim}|${reset} "
out+="${orange}${used_tokens}/${total_tokens}${reset} ${dim}(${reset}${green}${pct_used}%${reset}${dim})${reset}"
out+=" ${dim}|${reset} "
out+="effort: "
case "$effort_level" in
    low)    out+="${dim}low${reset}" ;;
    medium) out+="${orange}med${reset}" ;;
    *)      out+="${green}high${reset}" ;;
esac

# ===== Token + Cost stats =====
sep=" ${dim}|${reset} "

fmt_in=$(format_tokens "$session_input")
fmt_out=$(format_tokens "$session_output")

out+="${sep}${white}in:${reset} ${cyan}${fmt_in}${reset}"
out+=" ${white}out:${reset} ${cyan}${fmt_out}${reset}"

cost_aud=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $total_cost * 1.5}")
cost_aud_num=$(LC_NUMERIC=C awk "BEGIN {printf \"%.4f\", $total_cost * 1.5}")
if LC_NUMERIC=C awk "BEGIN {exit !($cost_aud_num >= 7.5)}"; then
    cost_color="$red"
elif LC_NUMERIC=C awk "BEGIN {exit !($cost_aud_num >= 1.5)}"; then
    cost_color="$orange"
else
    cost_color="$green"
fi
out+="${sep}${cost_color}A\$${cost_aud}${reset}"

# Output single line
printf "%b" "$out"

exit 0

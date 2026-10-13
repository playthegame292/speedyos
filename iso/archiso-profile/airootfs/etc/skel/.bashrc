# SpeedyOS ~/.bashrc
# Fast Paws. Arch Power.

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Shell options
shopt -s checkwinsize
shopt -s histappend
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=5000
HISTFILESIZE=10000

# Speedy Colors
_speedy_prompt() {
    local EXIT_CODE=$?
    local RESET='\[\e[0m\]'
    local BOLD='\[\e[1m\]'
    local WARM_BROWN='\[\e[38;5;172m\]'
    local CREAM='\[\e[38;5;223m\]'
    local CYAN='\[\e[38;5;74m\]'
    local GREEN='\[\e[38;5;71m\]'
    local RED='\[\e[38;5;203m\]'
    local GRAY='\[\e[38;5;244m\]'

    # Git branch integration
    local GIT_INFO=""
    if command -v git &>/dev/null; then
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ -n "$branch" ]]; then
            local git_status=""
            if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
                git_status="*"
            fi
            GIT_INFO=" ${GRAY}(${CYAN}${branch}${RED}${git_status}${GRAY})${RESET}"
        fi
    fi

    # Exit code indicator
    local STATUS_INFO=""
    if [[ $EXIT_CODE -ne 0 ]]; then
        STATUS_INFO="${RED}[${EXIT_CODE}]${RESET} "
    fi

    # Prompt construction:
    # 🐾 user@host:dir (branch*)
    # ❯
    # The Linux console (TERM=linux) and non-UTF-8 locales can't draw the
    # paw/arrow glyphs, so fall back to plain ASCII there.
    local PAW='🐾 ' ARROW='❯'
    if [[ $TERM == linux || ${LC_ALL:-${LC_CTYPE:-$LANG}} != *[Uu][Tt][Ff]* ]]; then
        PAW='' ARROW='>'
    fi
    PS1="${STATUS_INFO}${WARM_BROWN}${PAW}${BOLD}${CREAM}\u${GRAY}@${WARM_BROWN}\h${RESET}:${GREEN}\w${RESET}${GIT_INFO}\n${WARM_BROWN}${ARROW}${RESET} "
}

PROMPT_COMMAND=_speedy_prompt

# Useful SpeedyOS Aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Speedy commands are used as "speedy <command>" (see "speedy help").
# No bare aliases like "install" or "info": those would shadow real
# commands (install(1), info(1)) and surprise scripts and users.

# Display fastfetch/welcome banner once per login shell
if [[ -o login ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi

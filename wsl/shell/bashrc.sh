# --- dev-infra baseline shell config ---

# Sensible history
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Prompt: user@host:dir (git branch)
_git_branch() {
  git branch 2>/dev/null | sed -n 's/^\* //p'
}
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[33m\]$( b=$(_git_branch); [ -n "$b" ] && echo " ($b)")\[\e[0m\]\$ '

# Aliases
alias ll='ls -lah --color=auto'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'

# Docker: prefer Docker Desktop socket if available, fall back to native
if [[ -S /var/run/docker-desktop.sock ]]; then
  export DOCKER_HOST="unix:///var/run/docker-desktop.sock"
elif [[ -S /var/run/docker.sock ]]; then
  export DOCKER_HOST="unix:///var/run/docker.sock"
fi

# GitHub CLI completions
if command -v gh &>/dev/null; then
  eval "$(gh completion -s bash 2>/dev/null || true)"
fi

# nvm — enables `nvm use`, `nvm install`, etc. in interactive shells
# node/npm/npx are also available via /usr/local/bin symlinks for non-interactive use
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

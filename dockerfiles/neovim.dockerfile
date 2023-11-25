FROM --platform=linux/amd64 neovim-tmux-explorations-tmux:latest

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config

# Basic Neovim config & setup
COPY config/nvim $CONFDIR/nvim
RUN nvim --headless -c "Lazy" -c "qa"
RUN nvim --headless -c "TSInstall javascript json jq" -c "qa"
RUN nvim --headless -c "MasonInstall typescript-language-server jq-lsp json-lsp" -c "qa"

# Sample files
COPY samples ${HOMEDIR}

WORKDIR $HOMEDIR

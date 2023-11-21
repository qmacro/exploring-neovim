FROM --platform=linux/amd64 neovim-tmux-explorations-tmux:latest

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config

# Basic Neovim config & setup
COPY config/nvim $CONFDIR/nvim
RUN nvim --headless -c "Lazy" -c "qa" \
  && nvim --headless -c "MasonInstall typescript-language-server" -c "qa"

WORKDIR $HOMEDIR

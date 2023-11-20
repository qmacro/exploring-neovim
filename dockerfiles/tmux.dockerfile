FROM --platform=linux/amd64 neovim-tmux-explorations-base:latest

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config

# Basic Tmux config & setup
RUN git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
COPY config/tmux/tmux.conf $CONFDIR/tmux/
RUN $CONFDIR/tmux/plugins/tpm/bin/install_plugins

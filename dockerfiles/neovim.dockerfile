FROM --platform=linux/amd64 neovim-tmux-explorations-tmux:latest

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config

# Basic Neovim config & setup
COPY config/nvim $CONFDIR/nvim
RUN nvim --headless -c "Lazy" -c "qa"
RUN nvim --headless -c "TSInstall javascript json jq" -c "qa"
RUN nvim --headless -c "MasonInstall jq-lsp json-lsp lua-language-server typescript-language-server" -c "qa"

# Sample files
COPY samples ${HOMEDIR}
RUN npm install --global @sap/cds-dk
RUN cd $HOMEDIR && cds init --add sample bookshop

WORKDIR $HOMEDIR
CMD ["tmux", "-u"]

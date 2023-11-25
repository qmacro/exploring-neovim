FROM --platform=linux/amd64 neovim-tmux-explorations-tmux:latest

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config
ARG NVIMCONF=${CONFDIR}/nvim

# CAP installs
RUN npm install --global @sap/cds-dk @sap/cds-lsp

# Sample files
COPY samples ${HOMEDIR}
RUN cd ${HOMEDIR} && cds init --add sample bookshop

# Basic Neovim config & setup
COPY config/nvim ${NVIMCONF}
RUN nvim --headless -c "Lazy" -c "qa"
RUN nvim --headless -c "TSInstall javascript json jq" -c "qa"
RUN nvim --headless -c "MasonInstall jq-lsp json-lsp lua-language-server typescript-language-server" -c "qa"

# Install treesitter query files for CDS
RUN mkdir -p ${SETUPDIR} \
  && cd ${SETUPDIR} \
  && git clone https://github.com/cap-js-community/tree-sitter-cds \
  && mkdir -p ${NVIMCONF}/queries/cds/ \
  && cp tree-sitter-cds/nvim/*.scm ${NVIMCONF}/queries/cds/

# Clean up
#RUN rm -rf $SETUPDIR

WORKDIR ${HOMEDIR}
CMD ["tmux", "-u"]

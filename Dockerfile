FROM --platform=linux/amd64 debian:latest

ARG USERNAME=user

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    gcc \
    git \
    gnupg \
    golang \
    lf \
    libevent-dev \
    ncurses-dev \
    npm \
    shellcheck \
    unzip

# Ensure keyrings dir is there, for apt-based Docker and Node.js installs
RUN mkdir -p /etc/apt/keyrings

# Install docker CLI and Node.js
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Specific install of Node.js 20 (cds-lsp requires >=18.15.0).
# See https://github.com/nodesource/distributions
ARG NODE_MAJOR=20
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update

RUN apt-get install -y docker-ce-cli nodejs

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Definitions & basic setup
ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/home/${USERNAME}
ARG CONFDIR=${HOMEDIR}/.config
ARG NVIMCONF=${CONFDIR}/nvim

RUN adduser \
  --quiet \
  --disabled-password \
  --shell /bin/bash \
  --home $HOMEDIR \
  --gecos "Dev User" \
  $USERNAME

# Ensure I can run docker and connect from within a container to the Docker
# engine, as non-root user.
RUN groupadd docker && usermod -aG docker $USERNAME
RUN touch /var/run/docker.sock && chown $USERNAME:$USERNAME /var/run/docker.sock

RUN mkdir $SETUPDIR $CONFDIR ${CONFDIR}/nvim

RUN chmod 777 $SETUPDIR
RUN chown -R $USERNAME:$USERNAME $CONFDIR

# Install Ripgrep
RUN cd $SETUPDIR \
  && ls -l ..; touch TEST \
  && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb \
  && dpkg -i ripgrep_13.0.0_amd64.deb

# Install Neovim
RUN curl -L https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz \
  | tar xzf - -C /usr --strip-components 1

# Install Tmux
ARG TMUXVER=3.3a
RUN cd $SETUPDIR \
    && curl -fsSL "https://github.com/tmux/tmux/releases/download/$TMUXVER/tmux-$TMUXVER.tar.gz" \
    | tar -xzf - \
    && cd "tmux-$TMUXVER" && ./configure && make && make install

# Sensible CLI
COPY bashrcappends ${SETUPDIR}
RUN cat ${SETUPDIR}/bashrcappends >> ${HOMEDIR}/.bashrc

# Other config
COPY config/lf $CONFDIR/lf

# CAP installs
RUN npm install --global @sap/cds-dk @sap/cds-lsp

# Switch to container user for the following operations
USER $USERNAME

# Basic Tmux config & setup
RUN git clone https://github.com/tmux-plugins/tpm ${CONFDIR}/tmux/plugins/tpm
COPY config/tmux/tmux.conf $CONFDIR/tmux/
RUN $CONFDIR/tmux/plugins/tpm/bin/install_plugins
RUN echo 'Exploring tmux and neovim configuration' > $HOMEDIR/.focus-status

# Basic Neovim config & setup
COPY config/nvim ${CONFDIR}/nvim
RUN nvim --headless -c "Lazy" -c "qa"
RUN nvim --headless -c "TSInstall javascript json jq" -c "qa"
RUN nvim --headless -c "MasonInstall jq-lsp json-lsp lua-language-server typescript-language-server" -c "qa"

# TODO sort this out
USER root
RUN chown -R $USERNAME:$USERNAME $HOMEDIR
RUN rm -rf $HOMEDIR/go/
USER $USERNAME

# Install treesitter query files for CDS
RUN mkdir -p ${SETUPDIR} \
  && cd ${SETUPDIR} \
  && git clone https://github.com/cap-js-community/tree-sitter-cds \
  && mkdir -p ${NVIMCONF}/queries/cds/ \
  && cp tree-sitter-cds/nvim/*.scm ${NVIMCONF}/queries/cds/

## Sample files
COPY samples ${HOMEDIR}
#RUN cd ${HOMEDIR} && cds init --add sample bookshop

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["bash"]

CMD ["tmux", "-u"]

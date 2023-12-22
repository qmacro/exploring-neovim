# ---------------------------------------------------------------------
FROM --platform=linux/amd64 debian:latest as base

ARG USERNAME=user
ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    fzf \
    gcc \
    git \
    gnupg \
    golang \
    lf \
    libevent-dev \
    ncurses-dev \
    npm \
    pandoc \
    shellcheck \
    toot \
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
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------
FROM base as extra

RUN mkdir $SETUPDIR && chmod 777 $SETUPDIR

ARG GHVER=2.40.1
RUN cd $SETUPDIR \
  && curl -LO "https://github.com/cli/cli/releases/download/v${GHVER}/gh_${GHVER}_linux_amd64.deb" \
  && dpkg -i "./gh_${GHVER}_linux_amd64.deb"

ARG GLOWVER=1.5.1
RUN curl -sLO "https://github.com/charmbracelet/glow/releases/download/v${GLOWVER}/glow_${GLOWVER}_amd64.deb" \
  && dpkg -i "./glow_${GLOWVER}_amd64.deb"

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ARG JQVER=1.7
RUN curl \
    --silent \
    --location \
    --output $DEST/jq \
    --url "https://github.com/jqlang/jq/releases/download/jq-${JQVER}/jq-linux-amd64" \
    && chmod +x $DEST/jq

ARG IJQVER=0.4.1
RUN curl \
    --silent \
    --location \
    --url "https://git.sr.ht/~gpanders/ijq/refs/download/v$IJQVER/ijq-$IJQVER-linux-amd64.tar.gz" \
    | tar \
      --extract \
      --gunzip \
      --file - \
      --directory $DEST \
      --strip-components 1 \
      --wildcards \
      ijq-$IJQVER/ijq

ARG RIPGREPVER=13.0.0
RUN cd $SETUPDIR \
  && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREPVER}/ripgrep_${RIPGREPVER}_amd64.deb \
  && dpkg -i ripgrep_${RIPGREPVER}_amd64.deb

ARG NEOVIMVER=0.9.4
RUN curl -L https://github.com/neovim/neovim/releases/download/v${NEOVIMVER}/nvim-linux64.tar.gz \
  | tar xzf - -C /usr --strip-components 1

ARG TMUXVER=3.3a
RUN cd $SETUPDIR \
    && curl -fsSL "https://github.com/tmux/tmux/releases/download/$TMUXVER/tmux-$TMUXVER.tar.gz" \
    | tar -xzf - \
    && cd "tmux-$TMUXVER" && ./configure && make && make install

RUN cd $SETUPDIR \
    && curl \
      --remote-name \
      --location \
      --url "https://raw.githubusercontent.com/SAP-samples/sap-tech-bytes/2021-09-01-btp-cli/getbtpcli" \
    && chmod +x getbtpcli \
    && echo -ne '\n' | ./getbtpcli

# ---------------------------------------------------------------------
FROM extra as usersetup

# Definitions & basic setup
ARG HOME=/home/${USERNAME}
ARG CONFDIR=${HOME}/.config
ARG NVIMCONF=$HOME/.config/nvim

RUN adduser \
  --quiet \
  --disabled-password \
  --shell /bin/bash \
  --home $HOME \
  --gecos "Dev User" \
  $USERNAME

RUN mkdir $HOME/.config
RUN chown -R $USERNAME:$USERNAME $HOME/.config $HOME/.cache/

# ---------------------------------------------------------------------
FROM usersetup as npminstalls

# CAP installs
RUN \
  npm install --global \
    @sap/cds-dk \
    @sap/cds-lsp \
    jwt-cli \
    ramda \
    url-decode-encode-cli \
    yarn \
  && chown -R $USERNAME:$USERNAME $HOME/.npm/

# ---------------------------------------------------------------------
FROM npminstalls as coreconfig

# Switch to container user for the following operations
USER $USERNAME

# Bring in dotfiles
RUN git clone https://github.com/qmacro/dotfiles/ $HOME/dotfiles

# Basic Tmux config & setup
RUN \
    mkdir -p $HOME/.config/tmux/ \
 && ln -s $HOME/dotfiles/config/tmux/tmux.conf $HOME/.config/tmux/ \
 && git clone https://github.com/tmux-plugins/tpm $HOME/.config/tmux/plugins/tpm \
 && $HOME/.config/tmux/plugins/tpm/bin/install_plugins \
 && echo 'Devcontainers FTW!' > $HOME/.focus-status

# Basic Neovim config & setup
RUN \
    ln -s $HOME/dotfiles/config/nvim/ $HOME/.config/ \
 && nvim --headless -c "Lazy" -c "qa" \
 && nvim --headless -c "TSInstall javascript json jq" -c "qa" \
 && nvim --headless -c "MasonInstall jq-lsp json-lsp lua-language-server typescript-language-server" -c "qa" \
 && chmod -R +w $HOME/go/ && rm -rf $HOME/go/

# Install treesitter query files for CDS
RUN \
    cd ${SETUPDIR} \
 && git clone https://github.com/cap-js-community/tree-sitter-cds \
 && mkdir -p $HOME/.config/nvim/queries/cds/ \
 && cp tree-sitter-cds/nvim/*.scm $HOME/.config/nvim/queries/cds/

# Set up shell configuration
RUN \
    ln -s -f $HOME/dotfiles/bashrc $HOME/.bashrc; \
    ln -s -f $HOME/dotfiles/gitconfig $HOME/.gitconfig; \
    ln -s -f $HOME/dotfiles/config/lf/ $HOME/.config/; \
    ln -s -f $HOME/dotfiles/config/gh/ $HOME/.config/; \
    ln -s -f $HOME/dotfiles/config/g/ $HOME/.config/;

# ---------------------------------------------------------------------
FROM coreconfig as tempinstalls

USER root
RUN apt-get install -y iputils-ping

# ---------------------------------------------------------------------
FROM tempinstalls as finalsetup

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["tmux", "-u"]

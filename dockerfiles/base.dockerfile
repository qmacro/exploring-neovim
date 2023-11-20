FROM --platform=linux/amd64 debian:latest

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    build-essential \
    curl \
    fd-find \
    gcc \
    git \
    golang \
    lf \
    libevent-dev \
    ncurses-dev \
    nodejs \
    npm \
    shellcheck \
    unzip
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Definitions & basic setup
ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config
RUN mkdir $CONFDIR $SETUPDIR

# Install Ripgrep
RUN cd $SETUPDIR \
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

# Sample files
COPY samples ${HOMEDIR}

# Other config
COPY config/lf $CONFDIR/lf

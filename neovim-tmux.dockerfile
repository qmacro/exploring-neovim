FROM --platform=linux/amd64 debian:12

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    build-essential \
    curl \
    git \
    gcc \
    golang \
    libevent-dev \
    ncurses-dev \
    nodejs \
    npm \
    fd-find \
    unzip
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG DEST=/usr/local/bin
ARG SETUPDIR=/tmp/setup
ARG HOMEDIR=/root
ARG CONFDIR=${HOMEDIR}/.config

# Basic setup
RUN mkdir $CONFDIR 
RUN mkdir $SETUPDIR

# Ripgrep
RUN cd $SETUPDIR \
  && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb \
  && dpkg -i ripgrep_13.0.0_amd64.deb

# Neovim
RUN curl -L https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz \
  | tar xzf - -C /usr --strip-components 1

# Tmux
ARG TMUXVER=3.3a
RUN cd $SETUPDIR \
    && curl -fsSL "https://github.com/tmux/tmux/releases/download/$TMUXVER/tmux-$TMUXVER.tar.gz" \
    | tar -xzf - \
    && cd "tmux-$TMUXVER" && ./configure && make && make install

# Neovim config
RUN cd $SETUPDIR \
    && git clone https://github.com/qmacro/dotfiles \
    && cp -a dotfiles/config/nvim/ $CONFDIR

# Tmux config, including plugins
RUN mkdir $CONFDIR/tmux \
    && git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
COPY tmux.conf $CONFDIR/tmux/
RUN $CONFDIR/tmux/plugins/tpm/bin/install_plugins

# Sensible CLI
COPY bashrcappends ${SETUPDIR}
RUN cat ${SETUPDIR}/bashrcappends >> ${HOMEDIR}/.bashrc

# Tidy up
RUN rm -rf ${SETUPDIR}

# Off we go
CMD ["bash"]

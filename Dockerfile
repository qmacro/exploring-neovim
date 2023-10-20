from --platform=linux/amd64 debian

RUN apt-get update
RUN apt-get install -y curl git gcc golang nodejs npm fd-find unzip
RUN cd /tmp \
  && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb \
  && dpkg -i ripgrep_13.0.0_amd64.deb
RUN curl -L https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz \
  | tar xzf - -C /usr --strip-components 1
CMD ["bash"]

FROM ubuntu:jammy-20260731.1

# https://packages.ubuntu.com/
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential=12.9ubuntu3 \
  ca-certificates=20260601~22.04.1 \
  fzf=0.29.0-1ubuntu0.1 \
  git=1:2.34.1-1ubuntu1.17 \
  libevent-dev=2.1.12-stable-1build3 \
  libncurses-dev=6.3-2ubuntu0.2 \
  wget=1.21.2-2ubuntu1.4 \
  bison=2:3.8.2+dfsg-1build1 \
  byacc=1:2.0.20220114-1 \
  asciinema=2.1.0-1 \
  fonts-dejavu-core=2.37-2build1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

# https://github.com/tmux/tmux/releases
ARG TMUX_VERSION=3.7b
RUN mkdir /opt/tmux
WORKDIR /opt/tmux
RUN wget --progress=dot:giga https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz && \
  tar xzf tmux-${TMUX_VERSION}.tar.gz
WORKDIR /opt/tmux/tmux-${TMUX_VERSION}

RUN ./configure && \
  make && \
  make install && \
  ln -s /opt/tmux/tmux-${TMUX_VERSION}/tmux /usr/bin/tmux

# https://github.com/asciinema/agg/releases
ARG AGG_VERSION=1.9.0
RUN case "$(dpkg --print-architecture)" in \
  amd64) agg_arch=x86_64-unknown-linux-gnu ;; \
  arm64) agg_arch=aarch64-unknown-linux-gnu ;; \
  *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
  esac && \
  wget --progress=dot:giga -O /usr/local/bin/agg \
  "https://github.com/asciinema/agg/releases/download/v${AGG_VERSION}/agg-${agg_arch}" && \
  chmod +x /usr/local/bin/agg

RUN useradd -ms /bin/bash developer && \
  usermod -aG sudo developer
USER developer
WORKDIR /home/developer

COPY .tmux.conf /home/developer/
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins

ENTRYPOINT ["tmux"]

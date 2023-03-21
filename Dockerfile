FROM ubuntu:jammy-20230308

# https://packages.ubuntu.com/
RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates=20211016ubuntu0.22.04.1 \
  tmux=3.2a-4ubuntu0.2 \
  fzf=0.29.0-1 \
  git=1:2.34.1-1ubuntu1.8 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

RUN useradd -ms /bin/bash developer && \
  usermod -aG sudo developer
USER developer
WORKDIR /home/developer

COPY .tmux.conf /home/developer/
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins

ENTRYPOINT ["tmux"]

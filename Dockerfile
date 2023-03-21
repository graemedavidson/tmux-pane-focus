FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  tmux \
  fzf \
  git \
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

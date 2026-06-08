# Ubuntu LTS — dev shell w/ fish, git, gh, ripgrep, fd, Neovim, Starship, zoxide, Cursor CLI (agent)
FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    FNM_DIR=/opt/fnm-node

ARG UID=1000
ARG GID=1000

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    fish \
    gh \
    git \
    ripgrep \
    fd-find \
    neovim \
    openssh-server \
    sudo \
    unzip \
    zoxide \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && curl -fsSL --retry 3 --retry-delay 5 -o /tmp/fnm.zip \
    https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip \
  && unzip -o /tmp/fnm.zip -d /opt/fnm-bin \
  && chmod +x /opt/fnm-bin/fnm \
  && rm /tmp/fnm.zip \
  && ln -sf /opt/fnm-bin/fnm /usr/local/bin/fnm \
  && mkdir -p "${FNM_DIR}" \
  && if getent passwd "${UID}" >/dev/null; then userdel -r "$(getent passwd "${UID}" | cut -d: -f1)" 2>/dev/null || true; fi \
  && if ! getent group "${GID}" >/dev/null; then groupadd --gid "${GID}" dev; fi \
  && useradd --uid "${UID}" --gid "${GID}" --shell /usr/bin/fish --create-home dev \
  && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
  && chmod 0440 /etc/sudoers.d/dev \
  && mkdir -p /var/run/sshd \
  && chown -R dev:dev "${FNM_DIR}" \
  && printf '%s\n' \
    'set -gx FNM_DIR /opt/fnm-node' \
    'if type -q fnm' \
    '  fnm env --use-on-cd --shell fish | source' \
    'end' \
    > /etc/fish/conf.d/fnm.fish \
  && printf '%s\n' \
    'export FNM_DIR=/opt/fnm-node' \
    'eval "$(fnm env --shell bash)"' \
    > /etc/profile.d/fnm.sh \
  && chmod 644 /etc/profile.d/fnm.sh \
  && curl -fsSL --retry 3 --retry-delay 5 -o /tmp/starship.tar.gz \
    https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz \
  && tar -xzf /tmp/starship.tar.gz -C /usr/local/bin starship \
  && chmod +x /usr/local/bin/starship \
  && rm /tmp/starship.tar.gz \
  && zoxide init fish > /etc/fish/conf.d/zoxide.fish \
  && starship init fish > /etc/fish/conf.d/99-starship.fish \
  && zoxide init bash > /etc/profile.d/zoxide.sh \
  && starship init bash > /etc/profile.d/starship.sh \
  && chmod 644 /etc/fish/conf.d/zoxide.fish /etc/fish/conf.d/99-starship.fish /etc/profile.d/zoxide.sh /etc/profile.d/starship.sh \
  && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER dev
WORKDIR /home/dev

RUN bash -lc 'set -euo pipefail; eval "$(fnm env)" && fnm install 20 && fnm install 22 && fnm default 20'

USER root
RUN HOME=/root bash -c 'set -euo pipefail; export NO_COLOR=1; curl https://cursor.com/install -fsS | bash' \
  && ver_dir="$(dirname "$(readlink -f /root/.local/bin/agent)")" \
  && rm -rf /opt/cursor-agent/current \
  && mkdir -p /opt/cursor-agent \
  && cp -a "$ver_dir" /opt/cursor-agent/current \
  && ln -sf /opt/cursor-agent/current/cursor-agent /usr/local/bin/agent \
  && chmod -R a+rX /opt/cursor-agent/current \
  && printf '%s\n' \
    'if status is-interactive' \
    '  function agent --wraps agent' \
    '    command agent --yolo $argv' \
    '  end' \
    '  function a --wraps agent' \
    '    command agent --yolo $argv' \
    '  end' \
    'end' \
    > /etc/fish/conf.d/cursor-agent-yolo.fish \
  && chmod 644 /etc/fish/conf.d/cursor-agent-yolo.fish

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 22

USER dev
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sleep", "infinity"]

# Ubuntu LTS — dev shell w/ fish, git, ripgrep, fd, Cursor CLI (agent)
FROM ubuntu:24.04

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
    git \
    ripgrep \
    fd-find \
    sudo \
    unzip \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /opt/fnm-bin --skip-shell \
  && ln -sf /opt/fnm-bin/fnm /usr/local/bin/fnm \
  && mkdir -p "${FNM_DIR}" \
  && if getent passwd "${UID}" >/dev/null; then userdel -r "$(getent passwd "${UID}" | cut -d: -f1)" 2>/dev/null || true; fi \
  && if ! getent group "${GID}" >/dev/null; then groupadd --gid "${GID}" dev; fi \
  && useradd --uid "${UID}" --gid "${GID}" --shell /usr/bin/fish --create-home dev \
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
  && chmod -R a+rX /opt/cursor-agent/current

USER dev

CMD ["sleep", "infinity"]

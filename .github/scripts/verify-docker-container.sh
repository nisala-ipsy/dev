#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "verify-docker-container: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing binary: $1"
}

need_cmd fish
need_cmd git
need_cmd rg
need_cmd fd
need_cmd fnm
need_cmd node
need_cmd npm
need_cmd agent
need_cmd nvim
need_cmd starship
need_cmd zoxide

git --version >/dev/null || fail "git --version failed"
rg --version >/dev/null || fail "rg --version failed"
fd --version >/dev/null || fail "fd --version failed"
fish --version >/dev/null || fail "fish --version failed"
fnm --version >/dev/null || fail "fnm --version failed"

default_node="$(node --version)"
case "$default_node" in
  v20.*) ;;
  *) fail "default node should be v20.x, got ${default_node}" ;;
esac

n20="$(fnm exec --using=20 node --version)"
case "$n20" in
  v20.*) ;;
  *) fail "fnm exec --using=20: want v20.x, got ${n20}" ;;
esac

n22="$(fnm exec --using=22 node --version)"
case "$n22" in
  v22.*) ;;
  *) fail "fnm exec --using=22: want v22.x, got ${n22}" ;;
esac

fnm list | grep -qE '^.*v20\.' || fail "fnm list: no v20 line"
fnm list | grep -qE '^.*v22\.' || fail "fnm list: no v22 line"

def="$(fnm default)"
case "$def" in
  v20.*) ;;
  *) fail "fnm default should be v20.x, got ${def}" ;;
esac

agent --version >/dev/null || fail "agent --version failed"
nvim --version >/dev/null || fail "nvim --version failed"
starship --version >/dev/null || fail "starship --version failed"
zoxide --version >/dev/null || fail "zoxide --version failed"

echo "OK — binaries + Node ${default_node} (default), ${n20}, ${n22}, fnm default ${def}"

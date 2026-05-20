#!/usr/bin/env bash
set -euo pipefail

# XrayR one-click installer for Chan110011/XrayR-Test-source linux-64 release package.
# Usage:
#   bash <(curl -Ls https://raw.githubusercontent.com/Chan110011/XrayR-Test-source/main/release/install/install.sh)
#   bash <(curl -Ls https://raw.githubusercontent.com/Chan110011/XrayR-Test-source/main/release/install/install.sh) v0.9.5

REPO="${XRAYR_REPO:-Chan110011/XrayR-Test-source}"
VERSION="${1:-${XRAYR_VERSION:-v0.9.5}}"
ASSET="XrayR-linux-64.zip"
INSTALL_DIR="${XRAYR_INSTALL_DIR:-/usr/local/XrayR}"
CONFIG_DIR="${XRAYR_CONFIG_DIR:-/etc/XrayR}"
SERVICE_FILE="/etc/systemd/system/XrayR.service"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    red "请使用 root 权限运行：sudo bash install.sh"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    yellow "缺少 $1，正在尝试安装依赖..."
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update && apt-get install -y "$1"
    elif command -v yum >/dev/null 2>&1; then
      yum install -y "$1"
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y "$1"
    else
      red "请先安装 $1"
      exit 1
    fi
  }
}

check_arch() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  if [ "$os" != "linux" ]; then
    red "当前脚本只支持 Linux"
    exit 1
  fi
  case "$arch" in
    x86_64|amd64) ;;
    *) red "当前只提供 linux-64 包，不支持架构：$arch"; exit 1 ;;
  esac
}

install_files() {
  local url="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"
  green "下载 ${url}"
  curl -fL --retry 3 --connect-timeout 20 -o "$TMP_DIR/$ASSET" "$url" || {
    red "下载 XrayR 失败，请确认 release 里存在 ${ASSET}，以及服务器能够访问 GitHub。"
    exit 1
  }

  unzip -q "$TMP_DIR/$ASSET" -d "$TMP_DIR/XrayR"
  install -d "$INSTALL_DIR" "$CONFIG_DIR"
  install -m 755 "$TMP_DIR/XrayR/XrayR" "$INSTALL_DIR/XrayR"

  # Keep existing user config during upgrades.
  if [ ! -f "$CONFIG_DIR/config.yml" ]; then
    install -m 644 "$TMP_DIR/XrayR/config.yml" "$CONFIG_DIR/config.yml"
  else
    yellow "保留已有配置：$CONFIG_DIR/config.yml"
    install -m 644 "$TMP_DIR/XrayR/config.yml" "$CONFIG_DIR/config.yml.example.new"
  fi

  for f in dns.json route.json custom_outbound.json custom_inbound.json rulelist geoip.dat geosite.dat; do
    [ -f "$TMP_DIR/XrayR/$f" ] && install -m 644 "$TMP_DIR/XrayR/$f" "$CONFIG_DIR/$f"
  done
  [ -f "$TMP_DIR/XrayR/LICENSE" ] && install -m 644 "$TMP_DIR/XrayR/LICENSE" "$INSTALL_DIR/LICENSE"
  [ -f "$TMP_DIR/XrayR/README.md" ] && install -m 644 "$TMP_DIR/XrayR/README.md" "$INSTALL_DIR/README.md"
}

install_service() {
  cat > "$SERVICE_FILE" <<EOF_SERVICE
[Unit]
Description=XrayR Service
Documentation=https://github.com/${REPO}
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=${INSTALL_DIR}/XrayR -c ${CONFIG_DIR}/config.yml
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF_SERVICE

  systemctl daemon-reload
  systemctl enable XrayR >/dev/null 2>&1 || true
}

main() {
  need_root
  check_arch
  need_cmd curl
  need_cmd unzip
  install_files
  install_service
  green "XrayR ${VERSION} 安装完成。"
  echo "配置文件：${CONFIG_DIR}/config.yml"
  echo "启动：systemctl start XrayR"
  echo "状态：systemctl status XrayR --no-pager"
  echo "日志：journalctl -u XrayR -f"
}

main "$@"

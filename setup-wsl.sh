#!/usr/bin/env bash
# Toonflow WSL 一键初始化脚本
# 用法：在 Ubuntu 终端里执行  bash /mnt/c/ai/Toonflow-app/setup-wsl.sh
set -e

echo "==> [1/5] 更新 apt 并安装基础工具 (curl unzip git ffmpeg)"
sudo apt update
sudo apt install -y curl unzip git ffmpeg

echo "==> [2/5] 配置代理"
# 若 WSL 已通过 autoProxy(.wslconfig) 自动注入代理，则直接复用，不再手动设置
if [ -n "$HTTPS_PROXY" ] || [ -n "$HTTP_PROXY" ]; then
  echo "检测到已有代理（可能由 WSL autoProxy 注入）: ${HTTPS_PROXY:-$HTTP_PROXY}"
else
  # 兜底：手动探测 Windows 主机 IP（镜像网络模式下通常无需此步）
  WIN_HOST=$(ip route 2>/dev/null | grep default | awk '{print $3}' || true)
  if [ -n "$WIN_HOST" ]; then
    export HTTP_PROXY="http://$WIN_HOST:7892"
    export HTTPS_PROXY="http://$WIN_HOST:7892"
    export http_proxy="$HTTP_PROXY"
    export https_proxy="$HTTPS_PROXY"
    echo "代理已手动设为: $HTTPS_PROXY"
  else
    echo "未检测到代理，跳过（若能直连可忽略）"
  fi
fi

echo "==> [3/5] 安装 Bun 1.4.3 (项目锁定版本，不要用 latest)"
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.com/install | bash -s "bun-v1.4.3"
else
  echo "bun 已存在: $(bun --version)"
fi
export PATH="$HOME/.bun/bin:$PATH"
bun --version

echo "==> [4/5] 进入项目并安装依赖"
cd /mnt/c/ai/Toonflow-app
bun install

echo "==> [5/5] 启动 dev (前端 :5173 + 后端 :3000)"
echo "启动成功后，请在 Windows 浏览器打开 http://localhost:5173"
echo "（如需停止，按 Ctrl+C；之后重新启动只需再跑 bun run dev）"
bun run dev

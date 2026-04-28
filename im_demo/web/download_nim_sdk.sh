#!/bin/bash
# Copyright (c) 2022 NetEase, Inc. All rights reserved.
# Use of this source code is governed by a MIT license that can be
# found in the LICENSE file.

# ============================================================
# NIM Web SDK 预下载脚本
# 在执行 flutter build web 之前运行此脚本，将 NIM Web SDK
# 下载到 web/ 目录，避免用户运行时依赖外部 CDN 网络。
#
# 用法:
#   bash web/download_nim_sdk.sh
#   或在项目根目录执行:
#   bash example/web/download_nim_sdk.sh
# ============================================================

set -e

NIM_SDK_VERSION="10.9.80"
# V2 API 使用 dist/v2 目录下的 SDK
NIM_SDK_URL="https://unpkg.com/nim-web-sdk-ng@${NIM_SDK_VERSION}/dist/v2/NIM_BROWSER_SDK.js"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/NIM_BROWSER_SDK.js"

echo "================================================"
echo " NIM Web SDK 预下载脚本"
echo " 版本: nim-web-sdk-ng@${NIM_SDK_VERSION}"
echo " 目标: ${OUTPUT_FILE}"
echo "================================================"

# 检查 curl 是否可用
if ! command -v curl &> /dev/null; then
  echo "[ERROR] 未找到 curl，请先安装 curl 后重试。"
  exit 1
fi

echo "[INFO] 正在下载 NIM Web SDK..."
curl -fSL --progress-bar \
  -o "${OUTPUT_FILE}" \
  "${NIM_SDK_URL}"

if [ $? -eq 0 ]; then
  FILE_SIZE=$(du -sh "${OUTPUT_FILE}" | cut -f1)
  echo "[SUCCESS] 下载完成！文件大小: ${FILE_SIZE}"
  echo "[SUCCESS] 已保存至: ${OUTPUT_FILE}"
else
  echo "[ERROR] 下载失败，请检查网络连接后重试。"
  echo "[ERROR] 下载地址: ${NIM_SDK_URL}"
  exit 1
fi

echo ""
echo "现在可以执行 flutter build web 进行构建。"
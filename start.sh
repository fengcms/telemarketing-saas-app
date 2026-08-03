#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# 电销工作台 — 快捷开发脚本
# 用法：cd 到项目根目录后 ./start.sh
# ─────────────────────────────────────────────────────────

set -euo pipefail

# ── 颜色 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APK_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"
DEBUG_APK="$APK_DIR/app-debug.apk"
RELEASE_APK="$APK_DIR/app-release.apk"
PACKAGE_NAME="com.example.telemarketing_app"
PROD_API="https://tm-api.kao9.com"
TEST_API="https://tm-api-test.kao9.com"

# ── 开发工具参数 ──
# DEV_TOOLS=true 启用：登录页自动预填测试账号 + Alice 网络抓包浮窗
DEV_TOOLS="--dart-define=DEV_TOOLS=true"

# ── 辅助函数 ──

title()  { echo -e "\n${BLUE}═══════════════════════════════════════${NC}"; }
info()   { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()     { echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()    { echo -e "${RED}[ERR]${NC} $1"; }

# 检测是否有已连接的 adb 设备
check_adb() {
  if ! command -v adb &>/dev/null; then
    err "adb 未安装，请安装 Android SDK platform-tools"
    return 1
  fi
  local devices
  devices="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')"
  if [[ -z "$devices" ]]; then
    warn "没有检测到已连接的 Android 设备"
    return 1
  fi
  echo "$devices"
  return 0
}

# 检测 flutter
check_flutter() {
  if ! command -v flutter &>/dev/null; then
    err "flutter 未安装或不在 PATH 中"
    return 1
  fi
}

# ── 菜单选项 ──

menu_items=(
  "🚀 启动项目 (Chrome 测试模式 · 预填账号 + Alice)"
  "🌐 启动项目 (Chrome 生产模式 · 预填账号 + Alice + 正式环境)"
  "🔧 编译 Debug 版 APK（测试环境 · 预填账号 + Alice）"
  "📲 安装 Debug 版 APK 到手机"
  "📦 编译 Release 版 APK（生产环境）"
  "📲 安装 Release 版 APK 到手机"
  "🧹 清理构建缓存 (flutter clean)"
  "📥 安装依赖 (flutter pub get)"
  "🔍 代码静态分析 (flutter analyze)"
  "🔄 拉取最新代码 (git pull)"
  "⚡ 重启 adb ���务"
  "📋 查看已连接的 adb 设备"
  "🚚 一步到位：编译 Debug + 安装到手机"
  "🚚 一步到位：编译 Release + 安装到手机"
  "❌ 退出"
)

# ── 显示菜单 ──

show_menu() {
  clear
  echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║       📱 电销工作台 — 快捷开发工具箱        ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  for i in "${!menu_items[@]}"; do
    printf "  ${GREEN}%2d${NC})  %s\n" $((i + 1)) "${menu_items[$i]}"
  done
  echo ""
}

# ── 各选项执行逻辑 ──

option_run_chrome() {
  info "启动 Chrome 测试模式（接口：${TEST_API} · 预填测试账号 + Alice 网络抓包）..."
  no_proxy=* flutter run -d chrome "$DEV_TOOLS"
}

option_run_chrome_prod() {
  info "启动 Chrome 生产模式（接口：${PROD_API} · 预填测试账号 + Alice 网络抓包）..."
  no_proxy=* flutter run -d chrome "$DEV_TOOLS" --dart-define=API_BASE_URL="$PROD_API"
}

option_build_debug() {
  info "编译 Debug APK（接口：${TEST_API} · 预填测试账号 + Alice 网络抓包）..."
  cd "$PROJECT_DIR"
  no_proxy=* flutter build apk --debug "$DEV_TOOLS"
  ok "Debug APK 编译完成：$DEBUG_APK"
}

option_install_debug() {
  if ! check_adb; then return; fi
  if [[ ! -f "$DEBUG_APK" ]]; then
    warn "Debug APK 不存在，先编译..."
    option_build_debug
  fi
  info "安装 Debug APK 到手机..."
  adb install -r "$DEBUG_APK" || {
    warn "安装失败（可能签名不匹配），尝试先卸载旧版本..."
    adb uninstall "$PACKAGE_NAME" 2>/dev/null || true
    adb install -r "$DEBUG_APK" && ok "安装成功" || err "安装失败"
  }
  ok "✅ Debug APK 安装完成"
}

option_build_release() {
  info "编译 Release APK（接口：${PROD_API}）..."
  cd "$PROJECT_DIR"
  no_proxy=* flutter build apk --release --dart-define=API_BASE_URL="$PROD_API"
  ok "Release APK 编译完成：$RELEASE_APK"
}

option_install_release() {
  if ! check_adb; then return; fi
  if [[ ! -f "$RELEASE_APK" ]]; then
    warn "Release APK 不存在，先编译..."
    option_build_release
  fi
  info "安装 Release APK 到手机..."
  adb install -r "$RELEASE_APK" || {
    warn "安装失败（可能签名不匹配），尝试先卸载旧版本..."
    adb uninstall "$PACKAGE_NAME" 2>/dev/null || true
    adb install -r "$RELEASE_APK" && ok "安装成功" || err "安装失败"
  }
  ok "✅ Release APK 安装完成"
}

option_clean() {
  info "清理构建缓存..."
  cd "$PROJECT_DIR"
  flutter clean
  ok "构建缓存已清理"
}

option_pub_get() {
  info "安装/更新依赖..."
  cd "$PROJECT_DIR"
  no_proxy=* flutter pub get
  ok "依赖已安装"
}

option_analyze() {
  info "运行代码静态分析..."
  cd "$PROJECT_DIR"
  no_proxy=* flutter analyze
  ok "分析完成"
}

option_git_pull() {
  info "拉取最新代码..."
  cd "$PROJECT_DIR"
  git pull
  ok "代码已更新到最新"
}

option_restart_adb() {
  info "重启 adb 服务..."
  adb kill-server
  sleep 1
  adb start-server
  sleep 1
  adb devices
  ok "adb 服务已重启"
}

option_adb_devices() {
  info "已连接的 adb 设备："
  adb devices -l
}

option_build_and_install_debug() {
  option_build_debug
  option_install_debug
}

option_build_and_install_release() {
  option_build_release
  option_install_release
}

# ── 主循环 ──

while true; do
  show_menu
  read -rp "请选择操作 [1-${#menu_items[@]}]: " choice
  echo ""

  case "$choice" in
    1)  option_run_chrome ;;
    2)  option_run_chrome_prod ;;
    3)  option_build_debug ;;
    4)  option_install_debug ;;
    5)  option_build_release ;;
    6)  option_install_release ;;
    7)  option_clean ;;
    8)  option_pub_get ;;
    9)  option_analyze ;;
    10) option_git_pull ;;
    11) option_restart_adb ;;
    12) option_adb_devices ;;
    13) option_build_and_install_debug ;;
    14) option_build_and_install_release ;;
    15)
      echo -e "${GREEN}再见！${NC}"
      exit 0
      ;;
    *)
      warn "无效选项，请输入 1-${#menu_items[@]} 之间的数字"
      sleep 1
      continue
      ;;
  esac

  # 执行完后停顿让用户看到结果
  echo ""
  read -rp "按 Enter 返回菜单..."
done

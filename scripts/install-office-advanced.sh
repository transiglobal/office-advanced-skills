#!/bin/bash
# =============================================================================
# install-office-advanced.sh — 传米科技 OpenClaw 办公高级合集一键安装脚本
# 来源：https://github.com/transiglobal
# 用法：
#   本地安装：bash install-office-advanced.sh
#   远程安装：ssh user@host 'bash -s' < install-office-advanced.sh
#   curl安装：curl -fsSL https://raw.githubusercontent.com/transiglobal/office-advanced-skills/main/scripts/install-office-advanced.sh | bash
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
fail()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info()   { echo -e "${BLUE}[i]${NC} $1"; }
prompt() { echo -e "${YELLOW}[?]${NC} $1"; }

WORKSPACE_SKILLS="${HOME}/.openclaw/workspace/skills"
GLOBAL_SKILLS="${HOME}/.openclaw/skills"
ORG="https://github.com/transiglobal"
ENV_FILE="${HOME}/.openclaw/workspace/.env"

mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"

# ============================================================
# 阶段 0：询问用户所需的 API Key（非交互式可跳过）
# ============================================================
info "阶段 0：检查需要用户提供的配置..."

ask_api_key() {
  local var_name=$1
  local desc=$2
  local env_key=$3

  # 检查是否已存在于环境变量或 .env
  if [ -n "${!var_name:-}" ] || grep -q "^${env_key}=" "$ENV_FILE" 2>/dev/null; then
    log "${desc}：已配置，跳过"
    return 0
  fi

  # 非交互式检查（STDIN 不是终端时跳过）
  if [ ! -t 0 ]; then
    warn "${desc}：未提供，留空跳过（功能可能受限）"
    return 0
  fi

  prompt "${desc}（${env_key}，留空跳过）："
  read -r value < /dev/tty
  if [ -n "$value" ]; then
    echo "${env_key}=${value}" >> "$ENV_FILE"
    log "${desc}：已保存到 ${ENV_FILE}"
  else
    warn "${desc}：跳过"
  fi
}

# research-analyzer 需要 Tavily API Key
ask_api_key "TAVILY_API_KEY" "Tavily API Key（research-analyzer 用，可从 https://tavily.com 免费申请）" "TAVILY_API_KEY"

# paddleocr-doc-parsing 需要 PaddleOCR API 凭证
ask_api_key "PADDLEOCR_ACCESS_TOKEN" "PaddleOCR Access Token（paddleocr-doc-parsing 用，见 https://paddleocr.com）" "PADDLEOCR_ACCESS_TOKEN"
ask_api_key "PADDLEOCR_DOC_PARSING_API_URL" "PaddleOCR API URL（如 https://xxx.paddleocr.com/layout-parsing）" "PADDLEOCR_DOC_PARSING_API_URL"

# skywork-ppt 需要 Skywork Token
ask_api_key "SKYBOT_TOKEN" "Skywork Token（skywork-ppt 用，可从 https://skywork.ai 获取）" "SKYBOT_TOKEN"

echo ""

# ============================================================
# 阶段 1：克隆技能仓库
# ============================================================
info "阶段 1：克隆技能仓库..."

mkdir -p "$WORKSPACE_SKILLS"
mkdir -p "$GLOBAL_SKILLS"

WORKSPACE_REPOS=(
  "agent-reach:agent-reach"
  "claude-code:claude-code"
  "diagram-generator:diagram-generator"
  "douyin-hot-trend:douyin-hot-trend"
  "research-analyzer:research-analyzer"
  "skywork-ppt:skywork-ppt"
  "feishu-help-crawler:feishu-help-crawler"
  "paddleocr-doc-parsing:paddleocr-doc-parsing"
  "summarize:summarize"
)

GLOBAL_REPOS=()

clone_skill() {
  local repo=$1
  local dir_name=$2
  local target_dir=$3
  local dest="$target_dir/$dir_name"

  if [ -d "$dest" ]; then
    warn "已存在，跳过: $dir_name"
    return 0
  fi

  if git clone --depth=1 "$ORG/${repo}.git" "$dest" 2>/dev/null; then
    log "克隆成功: $dir_name"
  else
    fail "克隆失败: $repo，请检查网络或 GitHub 访问权限"
  fi
}

SUCCESS=0; FAIL=0
for item in "${WORKSPACE_REPOS[@]}"; do
  repo="${item%%:*}"; dir="${item##*:}"
  clone_skill "$repo" "$dir" "$WORKSPACE_SKILLS" && ((SUCCESS++)) || ((FAIL++))
done

echo ""
info "阶段 1 完成：成功 ${SUCCESS} 个，失败 ${FAIL} 个"

# ============================================================
# 阶段 2：自动安装依赖（无需用户介入）
# ============================================================
info "阶段 2：安装技能依赖（自动处理）..."

# --- Python 包（paddleocr, skywork-ppt）---
install_python_deps() {
  local dir=$1
  local req_file="${dir}/scripts/requirements.txt"
  local req_opt="${dir}/scripts/requirements-optimize.txt"

  if [ ! -f "$req_file" ]; then
    return 0
  fi

  info "安装 Python 依赖: $(basename "$dir")"

  # 尝试 pip3 安装，优先 --user，失败则尝试 --break-system-packages
  if ! pip3 install -r "$req_file" -q 2>/dev/null; then
    if ! pip3 install -r "$req_file" -q --break-system-packages 2>/dev/null; then
      # 最后尝试用户级虚拟环境
      if [ -d "${HOME}/.venv" ] || python3 -m venv "${HOME}/.venv" 2>/dev/null; then
        "${HOME}/.venv/bin/pip" install -r "$req_file" -q 2>/dev/null && log "  使用虚拟环境安装成功" || warn "  Python 依赖安装失败，可稍后手动安装"
      else
        warn "  Python 依赖安装失败，可稍后手动安装"
      fi
    else
      log "  安装成功（break-system-packages）"
    fi
  else
    log "  安装成功"
  fi
}

# --- Node 包（feishu-help-crawler 内置 node_modules，跳过）---
# wechat-toolkit 只需要 Node，无需额外安装

for skill in skywork-ppt paddleocr-doc-parsing; do
  dir="$WORKSPACE_SKILLS/$skill"
  [ -d "$dir" ] && install_python_deps "$dir"
done

# --- Playwright 浏览器（feishu-help-crawler）---
CRAWLER_DIR="$WORKSPACE_SKILLS/feishu-help-crawler"
if [ -d "$CRAWLER_DIR" ]; then
  if [ -d "$CRAWLER_DIR/scripts/node_modules/playwright" ]; then
    info "feishu-help-crawler: playwright 已内置，跳过"
  else
    info "feishu-help-crawler: 安装 playwright..."
    (cd "$CRAWLER_DIR/scripts" && npm install --loglevel=error -q 2>/dev/null || warn "  playwright 安装失败，请稍后手动: cd $CRAWLER_DIR/scripts && npm install")
  fi

  # 安装浏览器
  if ! "$CRAWLER_DIR/scripts/node_modules/.bin/playwright" --version &>/dev/null; then
    info "安装 Playwright Chromium 浏览器..."
    (cd "$CRAWLER_DIR/scripts" && npx playwright install chromium 2>/dev/null || warn "  Chromium 安装失败，可稍后手动: cd $CRAWLER_DIR/scripts && npx playwright install chromium")
  fi
fi

# --- skywork-ppt Python 依赖补充 ---
SKY_DIR="$WORKSPACE_SKILLS/skywork-ppt"
if [ -d "$SKY_DIR" ]; then
  info "skywork-ppt: 补充 python-pptx/pyyaml/requests..."
  pip3 install python-pptx pyyaml requests -q --break-system-packages 2>/dev/null || \
    pip3 install python-pptx pyyaml requests -q 2>/dev/null || true
fi

log "阶段 2 完成"

# ============================================================
# 阶段 3：自动配置（无需用户介入）
# ============================================================
info "阶段 3：自动配置..."

# 加载所有 API Key 到环境变量
for key in TAVILY_API_KEY PADDLEOCR_ACCESS_TOKEN PADDLEOCR_DOC_PARSING_API_URL SKYBOT_TOKEN; do
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    set -a
    source "$ENV_FILE"
    set +a
    log "${key}: 已加载"
  fi
done

# skywork-ppt: 验证 Token
SKY_AUTH="$WORKSPACE_SKILLS/skywork-ppt/scripts/skywork_auth.py"
if [ -f "$SKY_AUTH" ]; then
  if [ -n "${SKYBOT_TOKEN:-}" ]; then
    info "skywork-ppt: 验证 Token..."
    if python3 "$SKY_AUTH" --check 2>/dev/null; then
      log "skywork-ppt: Token 有效"
    else
      warn "skywork-ppt: Token 无效，请检查是否正确"
    fi
  else
    info "skywork-ppt: 未提供 SKYBOT_TOKEN，跳过验证"
  fi
fi

log "阶段 3 完成"

# ============================================================
# 完成
# ============================================================
echo ""
echo "=================================================="
echo "  ✅ 办公高级合集安装完成！"
echo "=================================================="
echo ""
echo "成功克隆 ${SUCCESS} 个技能，${FAIL} 个失败"
echo ""
echo "已自动处理："
echo "  ✅ 克隆所有技能仓库"
echo "  ✅ 安装 Python 依赖（pip 包）"
echo "  ✅ 安装 Playwright Chromium 浏览器"
echo "  ✅ 加载 API Key 到环境变量"
echo ""
echo "以下项目需用户配合，请确认是否已在安装时提供："
grep -q "^TAVILY_API_KEY=" "$ENV_FILE" 2>/dev/null && echo "  ✅ Tavily API Key（research-analyzer）" || echo "  ⚠️ Tavily API Key 未提供（research-analyzer 需用 https://tavily.com 申请）"
grep -q "^PADDLEOCR_ACCESS_TOKEN=" "$ENV_FILE" 2>/dev/null && echo "  ✅ PaddleOCR Access Token（paddleocr-doc-parsing）" || echo "  ⚠️ PaddleOCR Access Token 未提供（paddleocr-doc-parsing 需用 https://paddleocr.com 申请）"
grep -q "^PADDLEOCR_DOC_PARSING_API_URL=" "$ENV_FILE" 2>/dev/null && echo "  ✅ PaddleOCR API URL" || echo "  ⚠️ PaddleOCR API URL 未提供"
grep -q "^SKYBOT_TOKEN=" "$ENV_FILE" 2>/dev/null && echo "  ✅ Skywork Token（skywork-ppt）" || echo "  ⚠️ Skywork Token 未提供（skywork-ppt 需用 https://skywork.ai 获取）"
echo ""
echo "请重启 OpenClaw 会话使新技能生效。"
echo "=================================================="

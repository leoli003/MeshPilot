#!/bin/bash
# Comet Archive — automates the archive phase in one command
# Usage: comet-archive.sh <change-name> [--dry-run]
# Exit 0 = archive complete, exit 1 = fatal error

set -euo pipefail

COMET_BASH="${COMET_BASH:-${BASH:-bash}}"

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }

DRY_RUN=0
if [[ "${2:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Input validation
validate_change_name() {
  local name="$1"
  if [ -z "$name" ]; then
    red "FATAL: Change name cannot be empty"
    exit 1
  fi
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "FATAL: Invalid change name: '$name'"
    red "Valid characters: a-z, A-Z, 0-9, -, _"
    exit 1
  fi
  if [[ "$name" =~ \.\. ]]; then
    red "FATAL: Change name cannot contain '..'"
    exit 1
  fi
}

CHANGE="$1"
validate_change_name "$CHANGE"

CHANGE_DIR="openspec/changes/$CHANGE"
YAML="$CHANGE_DIR/.comet.yaml"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")" 2>/dev/null || dirname "$0")" && pwd)"
STATE_SH="$SCRIPT_DIR/comet-state.sh"
TODAY=$(date +%Y-%m-%d)

# 计算序号前缀：扫描归档目录，找到最大序号
# 序号格式：0001-名称（4位数字+连字符）
get_next_sequence() {
  local archive_base="openspec/changes/archive"
  local max_seq=0
  if [ -d "$archive_base" ]; then
    for dir in "$archive_base"/*; do
      [ -d "$dir" ] || continue
      local dirname
      dirname=$(basename "$dir")
      # 提取序号前缀（格式：0001-名称）
      # 必须是4位数字后面紧跟连字符
      # 日期格式 (2026-06-10-xxx) 匹配后会得到 2026，但后面紧跟 -06，不是单个连字符
      # 正确序号格式 (0001-xxx) 会匹配 0001 后面紧跟单个连字符
      local seq
      seq=$(echo "$dirname" | grep -oE '^[0-9]{4}-' 2>/dev/null | sed 's/-$//' || true)
      if [ -n "$seq" ]; then
        # 检查是否为真正的序号格式：4位数字后紧跟连字符，后面不是数字
        # 这样可以区分：0001-xxx（序号）和 2026-06-10-xxx（日期）
        local after_seq
        after_seq=$(echo "$dirname" | sed 's/^[0-9]\{4\}//')
        # 如果后面紧跟连字符+数字，说明是日期格式，跳过
        if echo "$after_seq" | grep -qE '^-[0-9]'; then
          continue
        fi
        if [ "$seq" -gt "$max_seq" ]; then
          max_seq=$seq
        fi
      fi
    done
  fi
  printf '%04d' $((max_seq + 1))
}

# 从 proposal.md 第一行提取中文标题
get_chinese_title() {
  local proposal_file="$CHANGE_DIR/proposal.md"
  if [ -f "$proposal_file" ]; then
    # 读取第一行，去掉 # 符号和前后空格
    local title
    title=$(head -1 "$proposal_file" | sed 's/^# *//' | sed 's/ *$//')
    echo "$title"
  else
    # 如果没有 proposal.md，使用 change-name
    echo "$CHANGE"
  fi
}

SEQ_PREFIX=$(get_next_sequence)
CHINESE_TITLE=$(get_chinese_title)
ARCHIVE_NAME="${SEQ_PREFIX}-${CHINESE_TITLE}"
ARCHIVE_DIR="openspec/changes/archive/${ARCHIVE_NAME}"

STEPS_OK=0
STEPS_TOTAL=0

step_ok() {
  green "  [OK] $1"
  STEPS_OK=$((STEPS_OK + 1))
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

step_fail() {
  red "  [FAIL] $1"
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

step_dry_run() {
  yellow "  [DRY-RUN] $1"
  STEPS_OK=$((STEPS_OK + 1))
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

echo "=== Comet Archive: $CHANGE ===" >&2

# --- Step 1: Read .comet.yaml, extract paths ---

yaml_field() {
  local field="$1"
  if [ -f "$STATE_SH" ]; then
    "$COMET_BASH" "$STATE_SH" get "$CHANGE" "$field" 2>/dev/null
  else
    if [ -f "$YAML" ]; then
      local value
      value=$(grep "^${field}:" "$YAML" 2>/dev/null | sed "s/^${field}: *//" || true)
      value=$(strip_inline_comment "$value")
      strip_wrapping_quotes "$value"
    fi
  fi
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\") printf '%s\n' "${value:1:${#value}-2}" ;;
    \'*\') printf '%s\n' "${value:1:${#value}-2}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

if [ ! -f "$YAML" ]; then
  red "FATAL: .comet.yaml not found in $CHANGE_DIR/"
  exit 1
fi

DESIGN_DOC=$(yaml_field "design_doc")
PLAN_PATH=$(yaml_field "plan")

# --- Step 2: Validate entry state ---

PHASE_VAL=$(yaml_field "phase")
VERIFY_VAL=$(yaml_field "verify_result")
ARCHIVED_VAL=$(yaml_field "archived")

if [ "$PHASE_VAL" != "archive" ]; then
  red "FATAL: phase is '$PHASE_VAL', expected 'archive'"
  exit 1
fi

if [ "$VERIFY_VAL" != "pass" ]; then
  red "FATAL: verify_result is '$VERIFY_VAL', expected 'pass'. Run comet-verify first."
  exit 1
fi

if [ "$ARCHIVED_VAL" = "true" ]; then
  red "FATAL: change already archived"
  exit 1
fi

step_ok "Entry state verified"

# --- Step 3: Check archive target ---

if [ -d "$ARCHIVE_DIR" ]; then
  red "FATAL: archive target already exists: $ARCHIVE_DIR"
  exit 1
fi

step_ok "Archive target available"

# --- Step 4: Sync delta specs → main specs ---

sync_delta_specs() {
  local delta_root="$CHANGE_DIR/specs"
  if [ ! -d "$delta_root" ]; then
    return 0
  fi

  for delta_spec_dir in "$delta_root"/*/; do
    [ -d "$delta_spec_dir" ] || continue
    local capability
    capability=$(basename "$delta_spec_dir")
    local delta_spec="$delta_spec_dir/spec.md"
    local main_spec="openspec/specs/$capability/spec.md"

    if [ ! -f "$delta_spec" ]; then
      continue
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      step_dry_run "Would sync: $capability → $main_spec"
      continue
    fi

    if [ ! -f "$main_spec" ]; then
      mkdir -p "openspec/specs/$capability"
    elif ! cmp -s "$main_spec" "$delta_spec"; then
      yellow "  [DIFF] Delta spec differs from main spec before sync: $capability"
      diff -u "$main_spec" "$delta_spec" >&2 || true
    fi
    cp "$delta_spec" "$main_spec"

    step_ok "Delta spec synced: $capability → openspec/specs/$capability/spec.md"
  done
}

sync_delta_specs

# --- Step 5: Annotate design doc frontmatter ---

annotate_frontmatter() {
  local file="$1"
  local extra_fields="$2"

  if [ ! -f "$file" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    step_dry_run "Would annotate: $file"
    return 0
  fi

  if head -1 "$file" | grep -q '^---'; then
    local tmp_file
    tmp_file=$(mktemp)
    awk -v archive="$ARCHIVE_NAME" -v extra="$extra_fields" '
      /^archived-with:/ { next }
      NR==1 && /^---/ { print; next }
      /^---/ && NR>1 {
        print "archived-with: " archive
        if (extra != "") print extra
        print; next
      }
      { print }
    ' "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
  else
    local tmp_file
    tmp_file=$(mktemp)
    {
      echo "---"
      echo "archived-with: $ARCHIVE_NAME"
      if [ -n "$extra_fields" ]; then
        echo "$extra_fields"
      fi
      echo "status: final"
      echo "---"
      cat "$file"
    } > "$tmp_file"
    mv "$tmp_file" "$file"
  fi

  step_ok "Annotated: $file"
}

if [ -n "$DESIGN_DOC" ] && [ "$DESIGN_DOC" != "null" ]; then
  annotate_frontmatter "$DESIGN_DOC" "status: final"
fi

# --- Step 6: Annotate plan frontmatter ---

if [ -n "$PLAN_PATH" ] && [ "$PLAN_PATH" != "null" ]; then
  annotate_frontmatter "$PLAN_PATH" ""
fi

# --- Step 7: Move change to archive ---

if [ "$DRY_RUN" -eq 1 ]; then
  step_dry_run "Would move: $CHANGE_DIR → $ARCHIVE_DIR"
else
  mkdir -p "openspec/changes/archive"
  # 尝试 mv，如果失败则使用 cp + rm 作为备选
  if mv "$CHANGE_DIR" "$ARCHIVE_DIR" 2>/dev/null; then
    step_ok "Moved to: $ARCHIVE_DIR"
  else
    yellow "  [FALLBACK] mv failed, using cp + rm instead"
    # 复制目录
    if cp -r "$CHANGE_DIR" "$ARCHIVE_DIR"; then
      # 更新归档目录中 .comet.yaml 的 handoff_context 路径
      if [ -f "$ARCHIVE_DIR/.comet.yaml" ]; then
        sed -i "s|openspec/changes/$CHANGE/|openspec/changes/archive/$ARCHIVE_NAME/|g" "$ARCHIVE_DIR/.comet.yaml"
      fi
      # 删除原始目录
      if rm -rf "$CHANGE_DIR"; then
        step_ok "Moved to: $ARCHIVE_DIR (via cp + rm)"
      else
        step_fail "Failed to remove original: $CHANGE_DIR"
      fi
    else
      step_fail "Failed to copy: $CHANGE_DIR → $ARCHIVE_DIR"
    fi
  fi
fi

# --- Step 8: Mark archived via comet-state transition ---

ARCHIVE_YAML="$ARCHIVE_DIR/.comet.yaml"

if [ "$DRY_RUN" -eq 1 ]; then
  step_dry_run "Would set archived: true in $ARCHIVE_YAML"
else
  if [ -f "$ARCHIVE_YAML" ]; then
    "$COMET_BASH" "$STATE_SH" transition "$ARCHIVE_NAME" archived >/dev/null
    step_ok "archived: true"
  else
    step_fail "archived: true (.comet.yaml not found after move)"
  fi
fi

# --- Step 9: Print summary ---

echo "" >&2
if [ "$DRY_RUN" -eq 1 ]; then
  yellow "Dry run complete. $STEPS_OK/$STEPS_TOTAL steps would succeed."
else
  green "Archive complete. $STEPS_OK/$STEPS_TOTAL steps succeeded."
fi

if [ "$STEPS_OK" -lt "$STEPS_TOTAL" ]; then
  exit 1
fi

exit 0

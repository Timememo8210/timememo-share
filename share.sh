#!/bin/bash
# share.sh - 一键发布分享页面到 timememo.net
# 用法: ./share.sh <html文件路径> [备注]
# 输出: 分享链接

set -e

REPO_DIR="/tmp/timememo-share"
REPO_URL="https://github.com/Timememo8210/timememo-share.git"
DOMAIN="timememo.net"
LOG_FILE="share-log.json"

# Generate random 6-char path (alphanumeric)
generate_id() {
  cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 6
}

# Check input
if [ -z "$1" ]; then
  echo "❌ 用法: ./share.sh <html文件路径> [备注]"
  echo "   例: ./share.sh ./report.html 给张总看的Intel报告"
  exit 1
fi

SOURCE_FILE="$1"
NOTE="${2:-}"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "❌ 文件不存在: $SOURCE_FILE"
  exit 1
fi

# Clone or update repo
if [ -d "$REPO_DIR" ]; then
  cd "$REPO_DIR" && git pull origin main
else
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# Generate unique ID
SHARE_ID=$(generate_id)
# Make sure it doesn't collide
while [ -d "s/$SHARE_ID" ]; do
  SHARE_ID=$(generate_id)
done

# Create share directory
mkdir -p "s/$SHARE_ID"
cp "$SOURCE_FILE" "s/$SHARE_ID/index.html"

# Copy any associated assets (images, css, etc in same directory)
SOURCE_DIR=$(dirname "$SOURCE_FILE")
for ext in png jpg jpeg gif svg css js webp; do
  for f in "$SOURCE_DIR"/*.$ext; do
    [ -f "$f" ] && cp "$f" "s/$SHARE_ID/"
  done
done

# Update log
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
python3 -c "
import json
with open('$LOG_FILE','r') as f:
    log = json.load(f)
log['$SHARE_ID'] = {
    'source': '$SOURCE_FILE',
    'note': '''$NOTE''',
    'created': '$TIMESTAMP'
}
with open('$LOG_FILE','w') as f:
    json.dump(log, f, indent=2, ensure_ascii=False)
"

# Commit and push
git add -A
git commit -m "Share: $SHARE_ID - $NOTE"
git push origin main

# Output
echo ""
echo "✅ 分享成功！"
echo "🔗 链接: https://$DOMAIN/s/$SHARE_ID"
echo "📋 备注: $NOTE"
echo ""
echo "删除方法: rm -rf s/$SHARE_ID && git add -A && git commit -m 'Remove: $SHARE_ID' && git push"

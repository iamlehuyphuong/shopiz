#!/bin/bash
# Xóa tất cả GitHub Actions cache cho repo
# Usage: GITHUB_TOKEN=ghp_xxx bash scratch/delete_gh_caches.sh

REPO="effiai-one/app.shopiz.pro"
TOKEN="${GITHUB_TOKEN}"

if [ -z "$TOKEN" ]; then
  echo "❌ Chưa set GITHUB_TOKEN!"
  echo "Cách lấy token:"
  echo "  1. Vào https://github.com/settings/tokens"
  echo "  2. Generate new token (classic)"
  echo "  3. Chọn scope: repo, actions"
  echo ""
  echo "Chạy lại:"
  echo "  GITHUB_TOKEN=ghp_xxx bash scratch/delete_gh_caches.sh"
  exit 1
fi

echo "🔍 Đang lấy danh sách cache..."

PAGE=1
TOTAL_DELETED=0

while true; do
  # Lấy danh sách cache (100 per page)
  RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/actions/caches?per_page=100&page=$PAGE")

  # Lấy cache IDs
  IDS=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
caches = data.get('actions_caches', [])
for c in caches:
    print(c['id'])
" 2>/dev/null)

  if [ -z "$IDS" ]; then
    echo "✅ Không còn cache nào. Tổng đã xóa: $TOTAL_DELETED"
    break
  fi

  # Xóa từng cache
  for ID in $IDS; do
    curl -s -X DELETE \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$REPO/actions/caches/$ID"
    TOTAL_DELETED=$((TOTAL_DELETED + 1))
    echo "  🗑  Đã xóa cache #$ID ($TOTAL_DELETED)"
  done

  # Luôn quay lại page 1 vì danh sách đã thay đổi
  PAGE=1
done

echo ""
echo "🎉 Hoàn tất! Đã xóa $TOTAL_DELETED caches."
echo ""
echo "Bước tiếp theo:"
echo "  1. Vào https://github.com/$REPO/actions/workflows/docker_build.yml"
echo "  2. Click 'Run workflow' → chọn branch 'staging' → Run"

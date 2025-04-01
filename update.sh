#!/bin/bash
REPO_DIR="/root/claims-made"
PATCHCOIN_CLI="/root/patchcoin-ce463154e90f/bin/patchcoin-cli"
SOURCE_INDEX_DIR="/root/.patchcoin/indexes/claimindex"
CLAIMS_DIR="${REPO_DIR}/claims"
INDEX_DIR="${REPO_DIR}/index"
CLAIMS_JSON="${REPO_DIR}/claims.json"
CLAIMS_COUNT_JSON="${REPO_DIR}/claims_count.json"
BLOCK_COUNT_JSON="${REPO_DIR}/block_count.json"

cd "$REPO_DIR" || exit 1
mkdir -p "$CLAIMS_DIR"
mkdir -p "$INDEX_DIR"

CLAIMS_DATA=$("$PATCHCOIN_CLI" getclaims "" 0)
echo "$CLAIMS_DATA" > "$CLAIMS_JSON"

CLAIMS_COUNT=$(echo "$CLAIMS_DATA" | jq 'length')
echo "$CLAIMS_COUNT" > "$CLAIMS_COUNT_JSON"

echo "$CLAIMS_DATA" | jq -c 'sort_by(.nTime)' | jq -c '.[]' |
awk -v claims_dir="$CLAIMS_DIR" '
BEGIN { counter = 1 }
{
    filename = sprintf("%s/%05d.json", claims_dir, counter);
    print $0 > filename;
    counter++;
}'

CURRENT_BLOCK=$("$PATCHCOIN_CLI" getblockcount)

echo "$CURRENT_BLOCK" > "$BLOCK_COUNT_JSON"

if [ $((CURRENT_BLOCK % 100)) -eq 0 ]; then
    rsync -a --delete "$SOURCE_INDEX_DIR/" "$INDEX_DIR/"
fi

if git diff --quiet && git diff --staged --quiet; then
    echo "No changes detected. Exiting."
    exit 0
fi

git add "$BLOCK_COUNT_JSON" "$CLAIMS_COUNT_JSON" "$CLAIMS_JSON" "$CLAIMS_DIR/" "$INDEX_DIR/"
git commit -m "Update claims data"
git push origin main

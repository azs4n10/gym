#!/usr/bin/env bash
# Build the web app and push it to the gh-pages branch (no GitHub Actions needed).
# Usage: tool/deploy_pages.sh [repo-name]
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="${1:-$(basename "$(git rev-parse --show-toplevel)")}"
REMOTE="$(git remote get-url origin)"

# Git Bash rewrites "/gym/" into a Windows path unless this is set.
export MSYS_NO_PATHCONV=1
flutter build web --release --base-href "/$REPO/"
grep -q "<base href=\"/$REPO/\">" build/web/index.html

touch build/web/.nojekyll
rm -rf build/web/.git
git -C build/web init -q
git -C build/web checkout -q -b gh-pages
git -C build/web add -A
git -C build/web -c commit.gpgsign=false commit -q -m "Deploy web build"
git -C build/web push -q -f "$REMOTE" gh-pages:gh-pages
rm -rf build/web/.git

gh api -X POST "repos/{owner}/{repo}/pages/builds" --jq .status

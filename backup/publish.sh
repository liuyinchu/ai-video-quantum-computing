#!/usr/bin/env bash
set -euo pipefail
tag=full-backup-20261030
source_commit=$(node -p 'JSON.parse(require("fs").readFileSync("backup/manifest.json","utf8")).source_commit')
if ! gh release view "$tag" --repo "$GH_REPO" >/dev/null 2>&1; then
 gh release create "$tag" --repo "$GH_REPO" --target "$source_commit" --draft --title "量子计算视频 · 完整工程备份（2026-10-30）" --notes-file backup/RELEASE.md
fi
gh release upload "$tag" dist/* --repo "$GH_REPO" --clobber
gh api "repos/$GH_REPO/releases/tags/$tag" > release-response.json
node --input-type=module <<'NODE'
import fs from 'node:fs';
import crypto from 'node:crypto';
const release=JSON.parse(fs.readFileSync('release-response.json','utf8'));
const expected=JSON.parse(fs.readFileSync('release-artifacts.json','utf8'));
const sums=fs.readFileSync('dist/SHA256SUMS');
expected.push({name:'SHA256SUMS',bytes:sums.length,sha256:crypto.createHash('sha256').update(sums).digest('hex')});
for(const item of expected){
 const asset=release.assets.find(a=>a.name===item.name);
 if(!asset||asset.state!=='uploaded'||asset.size!==item.bytes)throw new Error('Upload metadata mismatch: '+item.name);
 if(asset.digest && asset.digest!=='sha256:'+item.sha256)throw new Error('GitHub asset checksum mismatch: '+item.name);
 console.log('Release upload confirmed: '+item.name);
}
NODE
gh release edit "$tag" --repo "$GH_REPO" --draft=false
printf 'Verified Release: https://github.com/%s/releases/tag/%s\n' "$GH_REPO" "$tag" >> "$GITHUB_STEP_SUMMARY"
cat dist/verification.json >> "$GITHUB_STEP_SUMMARY"


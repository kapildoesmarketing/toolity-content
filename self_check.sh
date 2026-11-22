#!/usr/bin/env bash
# Runnable public-hygiene check for toolity-content: verifies zero private files, zero em dashes, zero internal paths, and GitHub file-size limits.
# Deisgned by Kapil Pidhwani: runs in < 1s with zero network calls.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$ROOT" << 'EOF'
import sys
from pathlib import Path

root = Path(sys.argv[1])
forbidden_names = {"spec.json", "FLOW_PROMPTS.md", "PRODUCTION_NOTES.md", "ui-pane-left.png", "ui-pane-right.png"}
banned_tokens = ["\u2014", "&mdash;", "/google/src/cloud/", "/usr/local/google/home/", "@google.com"]

file_count = 0
for p in root.rglob("*"):
    if ".git" in p.parts:
        continue
    assert p.name != "raw", f"Private raw/ directory found in public repo: {p.relative_to(root)}"
    if not p.is_file():
        continue
    file_count += 1
    assert p.name not in forbidden_names, f"Private studio input file found in public repo: {p.relative_to(root)}"
    size_mb = p.stat().st_size / (1024 * 1024)
    assert size_mb < 95, f"File exceeds safe GitHub raw size limit ({size_mb:.1f} MB): {p.relative_to(root)}"
    if p.suffix.lower() == ".md":
        txt = p.read_text(encoding="utf-8")
        for tok in banned_tokens:
            assert tok not in txt, f"Forbidden token {tok!r} found in {p.relative_to(root)}"

print(f"CONTENT_SELF_CHECK_PASS: {file_count} public files verified (zero private files, zero em dashes, all < 95 MB).")
EOF

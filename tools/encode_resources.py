#!/usr/bin/env python3
import os, re, sys, shutil, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC_PRIMARY = ROOT / 'resources'
SRC_FALLBACK = ROOT / 'fxserver' / 'resources'
DST = ROOT / 'dist-resources'

PT_PREFIX = 'pt-'
TEXT_EXTS = {'.lua', '.js', '.css', '.html', '.json'}

# Simple minifiers
_lua_comment_re = re.compile(r'--\[\[[\s\S]*?\]\]|--.*')
_js_comment_re = re.compile(r'/\*[\s\S]*?\*/|//.*')
_css_comment_re = re.compile(r'/\*[\s\S]*?\*/')
_html_comment_re = re.compile(r'<!--([\s\S]*?)-->', re.MULTILINE)
_whitespace_re = re.compile(r'\s+')

KEEPLINES = {'fxmanifest.lua'}


def minify_text(content: str, ext: str) -> str:
    if ext == '.lua':
        content = _lua_comment_re.sub('', content)
        # collapse multiple blank lines
        content = re.sub(r'\n{3,}', '\n\n', content)
        return content
    if ext == '.js':
        content = _js_comment_re.sub('', content)
        content = re.sub(r'\s+\n', '\n', content)
        return content
    if ext == '.css':
        content = _css_comment_re.sub('', content)
        content = content.replace('\n', '')
        content = re.sub(r'\s{2,}', ' ', content)
        return content
    if ext == '.html':
        content = _html_comment_re.sub('', content)
        # collapse whitespace between tags
        content = re.sub(r'>\s+<', '><', content)
        return content
    if ext == '.json':
        try:
            obj = json.loads(content)
            return json.dumps(obj, separators=(',', ':'))
        except Exception:
            return content
    return content


def should_copy(base: Path, path: Path) -> bool:
    # Only encode our custom pt-* resources
    try:
        parts = path.relative_to(base).parts
    except Exception:
        return False
    return len(parts) > 0 and parts[0].startswith(PT_PREFIX)


def encode_resources():
    if DST.exists():
        shutil.rmtree(DST)
    DST.mkdir(parents=True, exist_ok=True)

    sources = [SRC_PRIMARY, SRC_FALLBACK]
    seen = set()
    for base in sources:
        if not base.exists():
            continue
        for root, dirs, files in os.walk(base):
            rpath = Path(root)
            # filter only pt-* resource trees
            try:
                rel_parts = rpath.relative_to(base).parts
            except Exception:
                rel_parts = ()
            if len(rel_parts) >= 1 and not rel_parts[0].startswith(PT_PREFIX):
                continue
            for f in files:
                src_file = rpath / f
                if not should_copy(base, src_file.parent):
                    continue
                rel = src_file.relative_to(base)
                # don't overwrite if already copied from primary
                if rel in seen:
                    continue
                dst_file = DST / rel
                dst_file.parent.mkdir(parents=True, exist_ok=True)
                ext = src_file.suffix.lower()
                if f in KEEPLINES:
                    data = src_file.read_text(encoding='utf-8', errors='ignore')
                    out = data
                    dst_file.write_text(out, encoding='utf-8')
                elif ext in TEXT_EXTS:
                    data = src_file.read_text(encoding='utf-8', errors='ignore')
                    out = minify_text(data, ext)
                    dst_file.write_text(out, encoding='utf-8')
                else:
                    with open(src_file, 'rb') as rf, open(dst_file, 'wb') as wf:
                        wf.write(rf.read())
                seen.add(rel)
    print(f"Encoded resources copied to {DST}")

if __name__ == '__main__':
    encode_resources()

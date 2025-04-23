#!/usr/bin/env python3
import sys
import re
import yaml
from pathlib import Path
from string import Template

ROOT = Path(__file__).parent.parent
desc = yaml.safe_load((ROOT / "assets/desc.yml").read_text()) or {}
defaults = desc.get("defaults", {})
tmpl = Template(
    re.sub(r"\{\{\s*(\w+)\s*\}\}", r"${\1}",
           (ROOT / "assets/headers/sol.txt").read_text()))

# Collect .sol keys from YAML


def sol_keys(n, p=()):
  if isinstance(n, dict):
    for k, v in n.items():
      q = p + (k, )
      if k.endswith(".sol"): yield q
      yield from sol_keys(v, q)


# Strip SPDX, pragma, blanks, NatSpec


def strip_header(lines):
  i = 1 if lines and lines[0].startswith("// SPDX-License-Identifier") else 0
  while i < len(lines) and lines[i].strip().startswith("pragma solidity"):
    i += 1
  while i < len(lines) and not lines[i].strip():
    i += 1
  while i < len(lines) and lines[i].strip().startswith("/**"):
    while i < len(lines) and not lines[i].strip().endswith("*/"):
      i += 1
    i += 1
    while i < len(lines) and not lines[i].strip():
      i += 1
  return lines[i:]


pr = sk = err = 0
for key in sol_keys(desc):
  fp = ROOT.joinpath(*key)
  rel = fp.relative_to(ROOT)
  if not fp.is_file():
    print(f"🟡 Skipped {rel}")
    sk += 1
    continue
  node = desc
  for p in key:
    node = node.get(p, {})
  data = {
      **defaults,
      **{
          f: str(node.get(f, "") or "")
          for f in ("title", "short_desc", "desc", "dev_comment")
      }
  }
  header = tmpl.substitute(data)
  text = fp.read_text()
  lines = text.splitlines()
  body = "\n".join(strip_header(lines))
  new = f"{header}\n{body}\n"
  if new == text: continue
  try:
    fp.write_text(new)
    print(f"✔️ Processed {rel}")
    pr += 1
  except Exception as e:
    print(f"❌ Error writing {rel}: {e}")
    err += 1

print(f"Result: {pr} processed, {sk} skipped, {err} errors")
sys.exit(1 if err else 0)

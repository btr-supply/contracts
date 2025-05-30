"""
SPDX-License-Identifier: MIT
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@title Generate Diamond Deployer Script - Generates the DiamondDeployer.sol contract
@copyright 2025
@notice Python script that reads facet configurations (facets.json) and artifacts to generate a Solidity contract responsible
for deploying the diamond proxy and its initial facets

@dev Reads facets.json and build artifacts, uses templates/DiamondDeployer.sol.tpl. Part of the build process.
@author BTR Team
"""

#!/usr/bin/env python3
import json
import sys
import glob
import re
from pathlib import Path

# Paths
ROOT = Path(__file__).parent.parent
FACETS_CFG = ROOT / 'scripts' / 'facets.json'
TEMPLATE = Path(__file__).parent / 'templates' / 'DiamondDeployer.sol.tpl'


def OUT_DIR(b):
  """Calculates the output directory based on the build directory."""
  return Path(b).parent / 'utils' / 'generated'


def load_facets():
  try:
    return json.loads(FACETS_CFG.read_text())
  except Exception as e:
    sys.exit(f"Error loading facets config: {e}")


def find_artifact(f, b):
  """Finds the build artifact for a given facet name."""
  return next(iter(glob.glob(f"{b}/*/{f}.json", recursive=True)), None)


def generate_parts(cfg, build):
  facets = [
      f for f, c in cfg.items()
      if c.get('required') or find_artifact(f, build)
  ]
  # imports
  imports = "\n".join(f'import {{{f}}} from "@facets/{f}.sol";'
                      for f in facets)
  # initializers
  inits = []
  for i, f in enumerate(facets):
    if cfg[f].get('initializable'):
      # Skip AccessControlFacet as it's handled by diamond constructor
      if f == "AccessControlFacet":
        continue

      # Apply the consistent naming pattern
      init_func_name = f"initialize{f.replace('Facet', '')}"
      inits.append((f, i + 1, init_func_name))  # Store function name

  sel_specs = "\n    ".join(
      f"bytes4 init{f}Selector = {f}.{init_func}.selector;"
      for f, _, init_func in inits  # Use the stored function name
  )
  calls = "\n    ".join(
      f"(bool success{i},) = address(this).call(abi.encodePacked(init{f}Selector));\n    if(!success{i}){{}}"  # Use the selector variable name
      for f, i, _ in inits  # Index i is still correct
  )

  # fields & salts
  def field_name(f):
    """Converts facet name (CamelCase) to a snake_case field name."""
    # Add underscore before capital letters (except the first one)
    s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', f)
    # Handle cases like DAO -> d_a_o, then ensure lowercase
    s2 = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    # Remove _facet suffix if present
    return s2.replace('_facet', '')

  addrs = "\n    ".join(f"address {field_name(f)};" for f in facets)
  salts = "\n    ".join(f"bytes32 {field_name(f)};" for f in facets)
  # selector functions
  owned = {
      sel: fac
      for fac, cfg_item in cfg.items()
      for sel in cfg_item.get('ownedSelectors', [])
  }
  funcs = []
  for f in facets:
    art = find_artifact(f, build)
    if not art:
      continue
    mids = json.loads(Path(art).read_text()).get('methodIdentifiers', {})
    sels = [
        p for m, p in mids.items() if not m.startswith('constructor') and (
            m not in owned or owned[m] == f)
    ]
    prefix = [
        f"function get{f}Selectorst() public pure returns(bytes4[] memory) {{",
        f"  bytes4[] memory selectors = new bytes4[]({len(sels)});",
    ]
    middle = [f"  selectors[{i}] = 0x{p};" for i, p in enumerate(sels)]
    suffix = ["  return selectors;", "}"]
    lines = prefix + middle + suffix
    funcs.append("  ".join(lines))
  sel_funcs = "\n  ".join(funcs)
  conds = "\n    ".join(
      f'if(nameHash == keccak256(bytes("{f}"))) return get{f}Selectorst();'
      for f in facets)
  # deployments
  deploys = "\n    ".join(f"{f} _{f} = new {f}();" for f in facets)
  cuts = [f for f in facets if f != 'DiamondCutFacet']
  cuts_code = f"IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[]({len(cuts)});" + "".join(
      f" cuts[{i}] = IDiamondCut.FacetCut({{facetAddress: address(_{f}), action: IDiamondCut.FacetCutAction.Add, functionSelectors: get{f}Selectorst()}});"
      for i, f in enumerate(cuts))
  diamond_creation_code = "BTRDiamond diamond = new BTRDiamond(admin, treasury, address(_DiamondCutFacet));" if 'DiamondCutFacet' in facets else ''
  # returns
  fac_addrs = "\n    ".join(f"facets[{i}] = address(_{f});"
                            for i, f in enumerate(facets))
  fac_names = "\n    ".join(f'facetNames[{i}] = "{f}";'
                            for i, f in enumerate(facets))
  ret = f"address[] memory facets = new address[]({len(facets)});\n    {fac_addrs}\n    string[] memory facetNames = new string[]({len(facets)});\n    {fac_names}"
  det = "\n      ".join(
      f"{field_name(f)}: address(0){',' if i < len(facets)-1 else ''}"
      for i, f in enumerate(facets))
  return {
      'facet_imports': imports,
      'facet_initializations': '\n    '.join([sel_specs, calls]).strip(),
      'deployment_addresses_fields': addrs,
      'salts_fields': salts,
      'selector_functions': sel_funcs,
      'get_selectors_for_facet_conditions': conds,
      'deploy_facets': deploys,
      'facet_cuts': cuts_code,
      'diamond_creation': diamond_creation_code,
      'deployment_return': ret,
      'deterministic_return_fields': det,
      'deterministic_addresses_return_fields': det,
  }


def main():
  if len(sys.argv) < 2:
    sys.exit("Usage: python generate_deployer.py <build_directory>")
  build_dir = sys.argv[1]
  cfg = load_facets()
  parts = generate_parts(cfg, build_dir)
  tpl_content = TEMPLATE.read_text() if TEMPLATE.exists() else sys.exit(
      "Template not found")
  for k, v in parts.items():
    tpl_content = tpl_content.replace(f"{{{{ {k} }}}}", v)
  output_dir = OUT_DIR(build_dir)
  output_dir.mkdir(parents=True, exist_ok=True)
  (output_dir / 'DiamondDeployer.gen.sol').write_text(tpl_content)
  print(f"✔️ Generated DiamondDeployer.gen.sol at {output_dir}")


if __name__ == '__main__':
  main()

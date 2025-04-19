#!/usr/bin/env python3
import json, sys, glob, re
from pathlib import Path

# Paths
ROOT = Path(__file__).parent.parent
FACETS_CFG = ROOT / 'scripts' / 'facets.json'
TEMPLATE = Path(__file__).parent / 'templates' / 'DiamondDeployer.sol.tpl'
OUT_DIR = lambda b: Path(b).parent / 'utils' / 'generated'


def load_facets():
  try:
    return json.loads(FACETS_CFG.read_text())
  except Exception as e:
    sys.exit(f"Error loading facets config: {e}")


find_artifact = lambda f, b: next(
    iter(glob.glob(f"{b}/**/{f}.json", recursive=True)), None)


def generate_parts(cfg, build):
  facets = [
      f for f, c in cfg.items()
      if c.get('required') or find_artifact(f, build)
  ]
  # imports
  imports = "\n".join(f'import {{{f}}} from "@facets/{f}.sol";'
                      for f in facets)
  # initializers
  inits = [(f, i + 1) for i, f in enumerate(facets)
           if cfg[f].get('initializable')]
  sel_specs = "\n    ".join(
      f"bytes4 init{f}Selector = {f}.initialize{f}.selector;"
      for f, _ in inits)
  calls = "\n    ".join(
      f"(bool success{i},) = address(this).call(abi.encodePacked(init{f}Selector));\n    if(!success{i}){{}}"
      for f, i in inits)
  # fields & salts
  field = lambda f: re.sub(r'(.)([A-Z])', lambda m: m.group(1) + '_' + m.group(
      2), f).lower().replace('_facet', '')
  addrs = "\n    ".join(f"address {field(f)};" for f in facets)
  salts = "\n    ".join(f"bytes32 {field(f)};" for f in facets)
  # selector functions
  owned = {
      sel: fac
      for fac, cfg in cfg.items()
      for sel in cfg.get('ownedSelectors', [])
  }
  funcs = []
  for f in facets:
    art = find_artifact(f, build)
    if not art: continue
    mids = json.loads(Path(art).read_text()).get('methodIdentifiers', {})
    sels = [
        p for m, p in mids.items() if not m.startswith('constructor') and (
            m not in owned or owned[m] == f)
    ]
    prefix = [
        f"function get{f}Selectors() public pure returns(bytes4[] memory) {{",
        f"  bytes4[] memory selectors = new bytes4[]({len(sels)});",
    ]
    middle = [f"  selectors[{i}] = 0x{p};" for i, p in enumerate(sels)]
    suffix = ["  return selectors;", "}"]
    lines = prefix + middle + suffix
    funcs.append("  ".join(lines))
  sel_funcs = "\n  ".join(funcs)
  conds = "\n    ".join(
      f'if(nameHash == keccak256(bytes("{f}"))) return get{f}Selectors();'
      for f in facets)
  # deployments
  deploys = "\n    ".join(f"{f} _{f} = new {f}();" for f in facets)
  cuts = [f for f in facets if f != 'DiamondCutFacet']
  cuts_code = f"IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[]({len(cuts)});" + "".join(
      f" cuts[{i}] = IDiamondCut.FacetCut({{facetAddress: address(_{f}), action: IDiamondCut.FacetCutAction.Add, functionSelectors: get{f}Selectors()}});"
      for i, f in enumerate(cuts))
  diamond = f"BTRDiamond diamond = new BTRDiamond(admin, treasury, address(_DiamondCutFacet));" if 'DiamondCutFacet' in facets else ''
  # returns
  fac_addrs = "\n    ".join(f"facets[{i}] = address(_{f});"
                            for i, f in enumerate(facets))
  fac_names = "\n    ".join(f'facetNames[{i}] = "{f}";'
                            for i, f in enumerate(facets))
  ret = f"address[] memory facets = new address[]({len(facets)});\n    {fac_addrs}\n    string[] memory facetNames = new string[]({len(facets)});\n    {fac_names}"
  det = "\n      ".join(
      f"{field(f)}: address(0){',' if i < len(facets)-1 else ''}"
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
      'diamond_creation': diamond,
      'deployment_return': ret,
      'deterministic_return_fields': det,
      'deterministic_addresses_return_fields': det,
  }


def main():
  if len(sys.argv) < 2:
    sys.exit("Usage: python generate_deployer.py <build_directory>")
  build = sys.argv[1]
  cfg = load_facets()
  parts = generate_parts(cfg, build)
  tpl = TEMPLATE.read_text() if TEMPLATE.exists() else sys.exit(
      "Template not found")
  for k, v in parts.items():
    tpl = tpl.replace(f"{{{{ {k} }}}}", v)
  out = OUT_DIR(build)
  out.mkdir(parents=True, exist_ok=True)
  (out / 'DiamondDeployer.gen.sol').write_text(tpl)
  print(f"✔️ Generated DiamondDeployer.gen.sol at {out}")


if __name__ == '__main__':
  main()

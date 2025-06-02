#!/usr/bin/env python3
"""
Generate BTR deployment scripts and test base with embedded deployment logic.
Creates self-contained deployment logic in script and test files.
"""

import json
from pathlib import Path


def load_contracts_config():
  """Load contracts configuration from contracts.json."""
  script_dir = Path(__file__).parent
  config_path = script_dir / "contracts.json"

  with open(config_path, 'r') as f:
    return json.load(f)


def load_template(template_name: str) -> str:
  """Load a template file from the templates directory."""
  script_dir = Path(__file__).parent
  template_path = script_dir.parent / "templates" / template_name

  with open(template_path, 'r') as f:
    return f.read()


def get_facet_function_selectors(facet_name: str, owned_selectors: list,
                                 all_facets: dict) -> list:
  """
    Extract function selectors from compiled artifacts.
    If ownedSelectors is provided in config, use those.
    Otherwise, extract all functions from the compiled ABI and exclude functions owned by other facets.
    """
  if owned_selectors and len(owned_selectors) > 0:
    # Use the explicitly provided selectors from config
    return owned_selectors

  # Extract from compiled artifacts
  script_dir = Path(__file__).parent
  artifact_path = script_dir.parent / "evm" / "out" / f"{facet_name}.sol" / f"{facet_name}.json"

  if not artifact_path.exists():
    print(
        f"Warning: No compiled artifact found for {facet_name} at {artifact_path}"
    )
    return []

  try:
    with open(artifact_path, 'r') as f:
      artifact = json.load(f)

    # Collect all function signatures owned by other facets
    owned_by_others = set()
    for other_facet_name, other_facet_config in all_facets.items():
      if other_facet_name != facet_name:
        other_owned = other_facet_config.get('ownedSelectors', [])
        if other_owned and len(other_owned) > 0:
          owned_by_others.update(other_owned)

    function_signatures = []
    for item in artifact.get('abi', []):
      if item.get('type') == 'function':
        name = item.get('name', '')
        inputs = item.get('inputs', [])

        # Build function signature
        input_types = [inp.get('type', '') for inp in inputs]
        signature = f"{name}({','.join(input_types)})"

        # Only include if not owned by another facet
        if signature not in owned_by_others:
          function_signatures.append(signature)

    excluded_count = 0
    for item in artifact.get('abi', []):
      if item.get('type') == 'function':
        name = item.get('name', '')
        inputs = item.get('inputs', [])
        input_types = [inp.get('type', '') for inp in inputs]
        signature = f"{name}({','.join(input_types)})"
        if signature in owned_by_others:
          excluded_count += 1

    print(
        f"Extracted {len(function_signatures)} function selectors from {facet_name} artifact (excluded {excluded_count} owned by other facets)"
    )
    return function_signatures

  except Exception as e:
    print(f"Error reading artifact for {facet_name}: {e}")
    return []


def format_selectors_array(selectors: list) -> str:
  """Format function selectors as Solidity array initialization code."""
  if not selectors:
    return "bytes4[] memory selectors = new bytes4[](0);"

  # Convert function signatures to selector format
  formatted_selectors = []
  for sig in selectors:
    formatted_selectors.append(f'bytes4(keccak256("{sig}"))')

  # Generate inline array creation code
  array_size = len(formatted_selectors)
  lines = []
  lines.append(f"bytes4[] memory selectors = new bytes4[]({array_size});")

  # Add assignment statements for each selector
  for i, selector in enumerate(formatted_selectors):
    lines.append(f"        selectors[{i}] = {selector};")

  return "\n        ".join(lines)


def generate_initialization_calls(facets: dict) -> str:
  """Generate initialization calls for facets marked as initializable."""
  init_calls = []

  for facet_name, facet_config in facets.items():
    if not facet_config.get('includeInDeployer', True):
      continue

    if facet_config.get('initializable', False):
      # Special handling for different facets
      if facet_name == "RescueFacet":
        # RescueFacet has payable fallback, needs payable casting
        init_call = f"""
        // Initialize {facet_name}
        console.log("Initializing {facet_name}...");
        {facet_name}(payable(diamond)).initializeRescue();"""
      elif facet_name == "OracleFacet":
        # OracleFacet needs CoreAddresses parameter
        init_call = f"""
        // Initialize {facet_name}
        console.log("Initializing {facet_name}...");
        CoreAddresses memory coreAddresses = CoreAddresses({{
            gov: address(0),
            gas: address(0),
            usdt: address(0),
            usdc: address(0),
            weth: address(0),
            wbtc: address(0),
            __gap: [bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes("")]
        }});
        {facet_name}(diamond).initializeOracle(coreAddresses);"""
      else:
        # Standard initialization for other facets
        init_function_name = facet_name.replace(
            "Facet", "") if facet_name.endswith("Facet") else facet_name
        init_call = f"""
        // Initialize {facet_name}
        console.log("Initializing {facet_name}...");
        {facet_name}(diamond).initialize{init_function_name}();"""

      init_calls.append(init_call)

  return "\n".join(init_calls)


def generate_facet_deployment_code(facets: dict) -> tuple[str, str, str]:
  """Generate facet deployment code, imports, and initialization calls for embedded deployment."""
  facet_imports = []
  facet_deployments = []

  for facet_name, facet_config in facets.items():
    # Skip facets not included in deployment
    if not facet_config.get('includeInDeployer', True):
      continue

    # Add import
    facet_imports.append(
        f'import {{{facet_name}}} from "@facets/{facet_name}.sol";')

    # Get selectors for this facet - either from config or from compiled artifacts
    owned_selectors = facet_config.get('ownedSelectors', [])
    selectors = get_facet_function_selectors(facet_name, owned_selectors,
                                             facets)
    selector_array_creation = format_selectors_array(selectors)

    # Generate deployment code
    deployment_code = f"""
        // Deploy {facet_name}
        console.log("Deploying {facet_name}...");
        {{
            address facetAddr = CREATEX.deployCreate3(
                {facet_config["salt"]},
                type({facet_name}).creationCode
            );
            require(facetAddr == {facet_config["expectedAddress"]}, "{facet_name} address mismatch");
            console.log("{facet_name} deployed at:", facetAddr);

            // Create selectors for {facet_name}
            {selector_array_creation}
            initialCuts[cutIndex] = FacetCut({{
                facetAddress: facetAddr,
                action: FacetCutAction.Add,
                functionSelectors: selectors
            }});
            cutIndex++;
        }}"""

    facet_deployments.append(deployment_code)

  # Generate initialization calls
  initialization_calls = generate_initialization_calls(facets)

  return "\n".join(facet_imports), "\n".join(
      facet_deployments), initialization_calls


def generate_script(config: dict) -> str:
  """Generate the DiamondDeployer script with embedded deployment logic."""
  facets = config.get("facets", {})

  # Filter facets that should be included in deployment
  deployment_facets = {
      name: conf
      for name, conf in facets.items() if conf.get('includeInDeployer', True)
  }

  facet_imports, facet_deployments, initialization_calls = generate_facet_deployment_code(
      deployment_facets)

  # Get configuration values
  btr_config = config.get("BTR", {})
  diamond_config = config.get("BTRDiamond", {})

  template = load_template("DiamondDeployerScript.s.sol.tpl")

  return template.replace("{{FACET_IMPORTS}}", facet_imports)\
                .replace("{{BTR_SALT}}", btr_config.get("salt", "0x0"))\
                .replace("{{BTR_EXPECTED_ADDRESS}}", btr_config.get("expectedAddress", "address(0)"))\
                .replace("{{DIAMOND_SALT}}", diamond_config.get("salt", "0x0"))\
                .replace("{{DIAMOND_EXPECTED_ADDRESS}}", diamond_config.get("expectedAddress", "address(0)"))\
                .replace("{{FACET_COUNT}}", str(len(deployment_facets)))\
                .replace("{{FACET_DEPLOYMENTS}}", facet_deployments)\
                .replace("{{INITIALIZATION_CALLS}}", initialization_calls)


def generate_test(config: dict) -> str:
  """Generate the BaseDiamondTest with embedded deployment logic."""
  facets = config.get("facets", {})

  # Filter facets that should be included in deployment
  deployment_facets = {
      name: conf
      for name, conf in facets.items() if conf.get('includeInDeployer', True)
  }

  facet_imports, facet_deployments, initialization_calls = generate_facet_deployment_code(
      deployment_facets)

  # Get configuration values
  btr_config = config.get("BTR", {})
  diamond_config = config.get("BTRDiamond", {})

  template = load_template("BaseDiamondTest.t.sol.tpl")

  return template.replace("{{FACET_IMPORTS}}", facet_imports)\
                .replace("{{BTR_SALT}}", btr_config.get("salt", "0x0"))\
                .replace("{{BTR_EXPECTED_ADDRESS}}", btr_config.get("expectedAddress", "address(0)"))\
                .replace("{{DIAMOND_SALT}}", diamond_config.get("salt", "0x0"))\
                .replace("{{DIAMOND_EXPECTED_ADDRESS}}", diamond_config.get("expectedAddress", "address(0)"))\
                .replace("{{FACET_COUNT}}", str(len(deployment_facets)))\
                .replace("{{FACET_DEPLOYMENTS}}", facet_deployments)\
                .replace("{{INITIALIZATION_CALLS}}", initialization_calls)


def main():
  """Generate deployment script and test base."""
  config = load_contracts_config()

  # Get output directories
  script_dir = Path(__file__).parent
  script_output_dir = script_dir.parent / "evm" / "scripts"
  test_output_dir = script_dir.parent / "evm" / "tests"

  script_output_dir.mkdir(exist_ok=True)
  test_output_dir.mkdir(exist_ok=True)

  print("🔧 Generating BTR deployment files...")

  # Generate DiamondDeployer script
  script_code = generate_script(config)
  script_path = script_output_dir / "DiamondDeployerScript.gen.s.sol"
  with open(script_path, 'w') as f:
    f.write(script_code)
  print("✅ Generated DiamondDeployerScript.gen.s.sol")

  # Generate BaseDiamondTest
  test_code = generate_test(config)
  test_path = test_output_dir / "BaseDiamondTest.gen.t.sol"
  with open(test_path, 'w') as f:
    f.write(test_code)
  print("✅ Generated BaseDiamondTest.gen.t.sol")

  # Count facets for summary
  facets = config.get("facets", {})
  deployment_facets = {
      name: conf
      for name, conf in facets.items() if conf.get('includeInDeployer', True)
  }

  print(f"""
🎉 Generation complete!

📊 Summary:
- Deployment script: DiamondDeployerScript.gen.s.sol
- Test base: BaseDiamondTest.gen.t.sol
- Facets included: {len(deployment_facets)}

📁 Generated files use embedded deployment logic:
- No separate deployer contracts needed
- Self-contained deployment in script and test
- Uses CreateX for deterministic addresses
- Includes comprehensive logging and verification
- Automatically extracts function selectors from compiled artifacts
- Calls initialize functions for initializable facets

⚠️  Note: Function selectors are extracted from compiled artifacts when
    ownedSelectors is empty in contracts.json. Ensure facets are compiled
    before running this generator.
""")


if __name__ == "__main__":
  main()

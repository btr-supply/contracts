
# Lean deployment build targets
build-lean: ## Build only lean deployment scripts (via-ir)
	@cd evm && forge build --contracts utils/generated --via-ir

build-facets: ## Build only facets (no via-ir)
	@cd evm && forge build --contracts src/facets

build-optimized: ## Full optimized build
	@echo "🔧 Optimized build process..."
	@cd evm && forge build --contracts src/facets --skip utils/generated
	@python3 scripts/generate_lean_deployment.py evm/out
	@cd evm && forge build --contracts utils/generated --via-ir --skip src
	@cd evm && forge build --skip utils/generated
	@echo "✔️ Optimized build complete"

generate-lean: ## Generate lean deployment contracts
	@python3 scripts/generate_lean_deployment.py evm/out

.PHONY: build-lean build-facets build-optimized generate-lean

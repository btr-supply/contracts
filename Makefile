install-deps:
	@echo "Ensuring system dependencies are installed (via scripts/install_deps.sh)..."
	bash scripts/install_deps.sh
	@echo "Checking for uv command..."
	@command -v uv >/dev/null 2>&1 || { echo >&2 "Error: uv command not found. Please install uv first: https://github.com/astral-sh/uv"; exit 1; }
	@echo "Syncing Python environment and dependencies with uv..."
	uv sync
	@echo "Installing git hooks..."
	@command -v pre-commit >/dev/null 2>&1 || { echo >&2 "Error: pre-commit command not found. Please install pre-commit first: https://pre-commit.com/#install"; exit 1; }
	pre-commit install
	pre-commit install --hook-type commit-msg
	pre-commit install --hook-type pre-push
	pre-commit install --hook-type post-checkout
	@echo "Python dependencies installed successfully."

organize-imports:
	@echo "Organizing Solidity imports..."
	uv run python scripts/organize_imports.py

strip-headers:
	@echo "Stripping Solidity headers..."
	uv run python scripts/strip_headers.py

format: organize-imports
	@echo "Formatting code..."
	bash scripts/format_code.sh
	# @echo "Formatting headers..."
	# uv run python scripts/format_headers.py

python-lint-fix:
	@echo "Linting and fixing Python files with Ruff..."
	uv run ruff check . --fix

build:
	bash scripts/build.sh --sizes

test:
	bash scripts/test.sh

pre-commit: format python-lint-fix

# Git Hook Validations (can be integrated with pre-commit tool or run manually)
validate-commit-msg:
	@echo "Validating commit message format"
	uv run python scripts/check_name.py -c

validate-branch-name:
	@echo "Validating current branch name format..."
	uv run python scripts/check_name.py -b

pre-push:
	@echo "Validating format of commits+branch name to be pushed..."
	uv run python scripts/check_name.py -p

check-branch-main:
	@echo "Checking if current branch is main..."
	bash scripts/check_branch.sh main

publish-major: check-branch-main
	bash scripts/release.sh major

publish-minor: check-branch-main
	bash scripts/release.sh minor

publish-patch: check-branch-main
	bash scripts/release.sh patch

push-tags: pre-push
	@echo "Pushing main branch and tags to origin..."
	git push origin main --tags

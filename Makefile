install-deps:
	@echo "Ensuring system dependencies are installed (via scripts/install_deps.sh)..."
	bash scripts/install_deps.sh
	@echo "Checking for uv command..."
	@command -v uv >/dev/null 2>&1 || { echo >&2 "Error: uv command not found. Please install uv first: https://github.com/astral-sh/uv"; exit 1; }
	@echo "Syncing Python environment and dependencies with uv..."
	uv sync
	@echo "Python dependencies installed successfully."

format:
	@echo "Formatting code..."
	bash scripts/format-code.sh
	@echo "Formatting headers..."
	uv run python scripts/format_headers.py

python-lint-fix:
	@echo "Linting and fixing Python files with Ruff..."
	uv run ruff check . --fix

test:
	bash scripts/test.sh

pre-commit: format python-lint-fix

# Git Hook Validations (can be integrated with pre-commit tool or run manually)
validate-commit-msg:
	@echo "Validating commit message format"
	uv run python scripts/check-name.py -c

validate-branch-name:
	@echo "Validating current branch name format..."
	uv run python scripts/check-name.py -b

pre-push:
	@echo "Validating format of commits+branch name to be pushed..."
	uv run python scripts/check-name.py -p

check-branch-main:
	@echo "Checking if current branch is main..."
	bash scripts/check-branch.sh main

publish-major: check-branch-main
	bash scripts/release.sh major

publish-minor: check-branch-main
	bash scripts/release.sh minor

publish-patch: check-branch-main
	bash scripts/release.sh patch

push-tags: pre-push
	@echo "Pushing main branch and tags to origin..."
	git push origin main --tags

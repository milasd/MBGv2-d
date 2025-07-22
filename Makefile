.PHONY: check
check:
	@echo "Checking UV lock file consistency with 'pyproject.toml'"
	@uv sync --locked
	@echo "Linting code: Running Ruff"
	@uv run ruff check
	@echo "Static type checking: Running mypy"
	@uv run mypy MBGv2_dissertation

.PHONY: test
test:
	@echo "Testing code: Running pytest"
	@uv run pytest --cov --cov-config=pyproject.toml --cov-report=xml tests

.PHONY: install
install:
	@echo "Installing dependencies with UV"
	@uv sync

.PHONY: install-dev
install-dev:
	@echo "Installing all dependencies including dev dependencies"
	@uv sync --all-extras

.PHONY: format
format:
	@echo "Formatting code with Ruff"
	@uv run ruff format

.PHONY: lint-fix
lint-fix:
	@echo "Auto-fixing linting issues with Ruff"
	@uv run ruff check --fix

.PHONY: clean
clean:
	@echo "Cleaning up build artifacts"
	@rm -rf .pytest_cache/
	@rm -rf __pycache__/
	@rm -rf *.egg-info/
	@rm -rf build/
	@rm -rf dist/
	@find . -type d -name __pycache__ -exec rm -rf {} +
	@find . -type f -name "*.pyc" -delete



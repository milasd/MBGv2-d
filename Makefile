.PHONY: check
check:
	@echo "Checking Poetry lock file consistency with 'pyproject.toml': Running poetry check --lock"
	@poetry check --lock
	@echo "Linting code: Ruff"
	@ruff check
	@echo "Static type checking: Running mypy"
	@poetry run mypy MBGv2_dissertation

.PHONY: test
test:
	@echo "Testing code: Running pytest"
	@poetry run pytest --cov --cov-config=pyproject.toml --cov-report=xml tests

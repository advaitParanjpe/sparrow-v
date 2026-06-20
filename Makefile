PYTHON ?= python3

.PHONY: check docs-check status test lint clean

check:
	$(PYTHON) scripts/check_repo.py --all

docs-check:
	$(PYTHON) scripts/check_repo.py --docs-only

status:
	@sed -n '1,240p' STATUS.md

test:
	$(PYTHON) -m unittest discover -s tb/tests -p 'test_*.py'

lint: check

clean:
	@echo "Phase 0 has no generated build artifacts to clean."

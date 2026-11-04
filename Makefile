MITAKA = vendor/mitaka
DATA_ROOT ?= $(abspath resources/data)
export DATA_ROOT

.PHONY: all build test reference-test data-test smoke run check-source check-data
all: build

check-source:
	@test -f "$(MITAKA)/native/gui/Makefile" || { echo 'Bundled Mitaka source is missing.' >&2; exit 1; }

check-data:
	@case "$${DATA_ROOT}" in /*) ;; *) echo 'Set DATA_ROOT to an absolute data directory.' >&2; exit 1 ;; esac
	@test -f "$${DATA_ROOT}/hip.dat" && test -f "$${DATA_ROOT}/cf96.dat" || { echo 'DATA_ROOT must contain hip.dat and cf96.dat.' >&2; exit 1; }

build: check-source
	$(MAKE) -C "$(MITAKA)/native/gui" all

test: check-source
	$(MAKE) -C "$(MITAKA)/native/core" test
	$(MAKE) -C "$(MITAKA)/native/gui" test controller-test

reference-test: check-source check-data
	CF96_DATA="$${DATA_ROOT}/cf96.dat" $(MAKE) -C "$(MITAKA)/native/core" reference-test rotation-reference-test lunar-reference-test atmosphere-reference-test eclipse-reference-test

data-test: check-source check-data
	$(MAKE) -C "$(MITAKA)/native/core" DATA_ROOT="$$(dirname "$${DATA_ROOT%/}")" data-test
	$(MAKE) -C "$(MITAKA)/native/gui" data-test

run: check-source check-data
	$(MAKE) -C "$(MITAKA)/native/gui" run

smoke: check-source check-data
	$(MAKE) -C "$(MITAKA)/native/gui" smoke

SHELL := /bin/bash
VERSION := 0.1
BUILD_DIR := build
ISO_NAME := nexora-$(VERSION).iso
ISO := $(BUILD_DIR)/$(ISO_NAME)

export VERSION
export BUILD_DIR

.PHONY: help bootstrap lint unit build integration test qemu qemu-serial release-notes clean

help:
	@echo "NEXORA build targets"
	@echo "  make bootstrap    install host build prerequisites (Linux, needs sudo)"
	@echo "  make lint         shellcheck all scripts + validate config files"
	@echo "  make unit         run repository-local unit tests"
	@echo "  make build        build the bootable NEXORA development ISO"
	@echo "  make integration  run integration tests against the built ISO"
	@echo "  make test         lint + unit + integration"
	@echo "  make qemu         boot the ISO in QEMU under UEFI (interactive)"
	@echo "  make qemu-serial  headless UEFI boot, write serial log to $(BUILD_DIR)"
	@echo "  make clean        remove $(BUILD_DIR)"

bootstrap:
	./scripts/bootstrap.sh

lint:
	./scripts/lint.sh

unit:
	bash tests/unit/test_configs.sh

build: lint unit
	./scripts/build-iso.sh

integration: build
	bash tests/integration/test_build.sh

test: lint unit integration
	@echo "ALL TESTS PASSED"

qemu: build
	./scripts/run-qemu.sh --iso $(ISO)

qemu-serial: build
	./scripts/run-qemu.sh --iso $(ISO) --headless

clean:
	rm -rf $(BUILD_DIR)
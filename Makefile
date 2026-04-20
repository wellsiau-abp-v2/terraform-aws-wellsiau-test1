# Module Template Makefile — Local Development Targets
#
# Targets:
#   init          — terraform init -backend=false
#   validate      — terraform validate (depends on init)
#   fmt           — terraform fmt -recursive
#   fmt-check     — terraform fmt -recursive -check (CI-style)
#   lint          — tflint with .config/.tflint.hcl
#   test          — terraform test (depends on init)
#   docs          — regenerate README.md via terraform-docs
#   security-scan — run ASH CLI (requires Docker)
#   build         — placeholder for modules with application code
#   clean         — remove generated files
#   all           — fmt, validate, lint, docs (default)
#
# Prerequisites:
#   Terraform CLI >= 1.7.0, tflint, terraform-docs, pre-commit
#   security-scan requires Docker and ASH CLI installed locally

.DEFAULT_GOAL := all

.PHONY: init validate fmt fmt-check lint test docs security-scan build clean all

init:
	terraform init -backend=false

validate: init
	terraform validate

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

lint:
	tflint --init --config .config/.tflint.hcl
	tflint --force --config .config/.tflint.hcl

test: init
	terraform test

docs:
	terraform-docs --config .config/.terraform-docs.yaml --lockfile=false ./

security-scan:
	@echo "Running ASH CLI security scan (requires Docker)..."
	ash --source-dir . --output-dir /tmp/ash-output

# Placeholder: modules with application code (e.g., Lambda functions) should
# implement build logic here and in subdirectory Makefiles.
build:
	@echo "No build step configured. See README for details on enabling build steps."

clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f tests/terraform.auto.tfvars
	rm -rf /tmp/ash-output

all: fmt validate lint docs

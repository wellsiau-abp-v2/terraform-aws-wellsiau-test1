# Module Template Makefile — Local Development Targets
#
# Targets:
#   tools         — install pinned versions of all CI tools locally
#   check-tools   — verify all required tools are installed
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
#   Run 'make tools' to install all required tools, or 'make check-tools' to verify.
#   security-scan requires Docker and ASH CLI installed locally.

# ── Tool versions (keep in sync with central-repo CI workflow) ──
TFLINT_VERSION       := 0.53.0
TERRAFORM_DOCS_VERSION := 0.19.0
CHECKOV_VERSION      := 3.2.255
SHELLCHECK_VERSION   := 0.10.0
MDL_VERSION          := 0.13.0

# ── Install location ──
INSTALL_DIR := /usr/local/bin

# ── Resolve mdl binary (Homebrew Ruby is keg-only on macOS) ──
BREW_RUBY_PREFIX := $(shell brew --prefix ruby 2>/dev/null)
BREW_GEM_BIN := $(shell $(BREW_RUBY_PREFIX)/bin/ruby -r rubygems -e 'puts Gem.default_bindir' 2>/dev/null)
MDL := $(shell command -v mdl 2>/dev/null || echo $(BREW_GEM_BIN)/mdl)

.DEFAULT_GOAL := all

.PHONY: tools check-tools init validate fmt fmt-check lint test docs security-scan build clean all

# ── Tool Installation ──

tools:
	@echo "Installing pinned CI tool versions for local development..."
	@OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	echo "Detected OS=$$OS ARCH=$$ARCH"; \
	echo ""; \
	echo "── tflint $(TFLINT_VERSION) ──"; \
	if [ "$$ARCH" = "arm64" ] || [ "$$ARCH" = "aarch64" ]; then TF_ARCH="arm64"; else TF_ARCH="amd64"; fi; \
	curl -sL "https://github.com/terraform-linters/tflint/releases/download/v$(TFLINT_VERSION)/tflint_$${OS}_$${TF_ARCH}.zip" -o /tmp/tflint.zip; \
	unzip -o /tmp/tflint.zip -d /tmp; \
	sudo mv /tmp/tflint $(INSTALL_DIR)/tflint; \
	rm /tmp/tflint.zip; \
	tflint --version; \
	echo ""; \
	echo "── terraform-docs $(TERRAFORM_DOCS_VERSION) ──"; \
	if [ "$$OS" = "darwin" ]; then TD_OS="darwin"; else TD_OS="linux"; fi; \
	curl -sL "https://github.com/terraform-docs/terraform-docs/releases/download/v$(TERRAFORM_DOCS_VERSION)/terraform-docs-v$(TERRAFORM_DOCS_VERSION)-$${TD_OS}-$${TF_ARCH}.tar.gz" -o /tmp/terraform-docs.tar.gz; \
	tar -xzf /tmp/terraform-docs.tar.gz -C /tmp terraform-docs; \
	sudo mv /tmp/terraform-docs $(INSTALL_DIR)/terraform-docs; \
	rm /tmp/terraform-docs.tar.gz; \
	terraform-docs --version; \
	echo ""; \
	echo "── shellcheck $(SHELLCHECK_VERSION) ──"; \
	if [ "$$OS" = "darwin" ]; then \
	  echo "shellcheck has no official darwin_arm64 binary — installing via Homebrew"; \
	  brew install shellcheck; \
	else \
	  curl -sL "https://github.com/koalaman/shellcheck/releases/download/v$(SHELLCHECK_VERSION)/shellcheck-v$(SHELLCHECK_VERSION).linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz; \
	  tar -xJf /tmp/shellcheck.tar.xz -C /tmp shellcheck-v$(SHELLCHECK_VERSION)/shellcheck; \
	  sudo mv /tmp/shellcheck-v$(SHELLCHECK_VERSION)/shellcheck $(INSTALL_DIR)/shellcheck; \
	  rm -rf /tmp/shellcheck.tar.xz /tmp/shellcheck-v$(SHELLCHECK_VERSION); \
	fi; \
	shellcheck --version; \
	echo ""; \
	echo "── checkov $(CHECKOV_VERSION) ──"; \
	pip install --quiet checkov==$(CHECKOV_VERSION); \
	checkov --version; \
	echo ""; \
	echo "── mdl $(MDL_VERSION) ──"; \
	if [ "$$OS" = "darwin" ]; then \
	  if ! brew list ruby >/dev/null 2>&1; then \
	    echo "Installing Homebrew Ruby (macOS system Ruby is too old)..."; \
	    brew install ruby; \
	  fi; \
	  BREW_RUBY_BIN=$$(brew --prefix ruby)/bin; \
	  "$$BREW_RUBY_BIN/gem" install mdl -v $(MDL_VERSION) --no-document; \
	  MDL_PATH=$$($$BREW_RUBY_BIN/ruby -r rubygems -e 'puts Gem.default_bindir')/mdl; \
	  echo "mdl installed at: $$MDL_PATH"; \
	  "$$MDL_PATH" --version; \
	else \
	  gem install mdl -v $(MDL_VERSION) --no-document; \
	  mdl --version; \
	fi; \
	echo ""; \
	echo "All tools installed."

check-tools:
	@echo "Checking required tools..."
	@FAIL=0; \
	for tool in terraform tflint terraform-docs checkov shellcheck; do \
	  if command -v $$tool >/dev/null 2>&1; then \
	    printf "  ✅ %-16s %s\n" "$$tool" "$$($$tool --version 2>&1 | head -1)"; \
	  else \
	    printf "  ❌ %-16s not found\n" "$$tool"; \
	    FAIL=1; \
	  fi; \
	done; \
	if $(MDL) --version >/dev/null 2>&1; then \
	  printf "  ✅ %-16s %s\n" "mdl" "$$($(MDL) --version 2>&1 | head -1)"; \
	else \
	  printf "  ❌ %-16s not found\n" "mdl"; \
	  FAIL=1; \
	fi; \
	if [ $$FAIL -eq 1 ]; then \
	  echo ""; \
	  echo "Missing tools detected. Run 'make tools' to install them."; \
	  exit 1; \
	fi; \
	echo ""; \
	echo "All tools available."

# ── Terraform Targets ──

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

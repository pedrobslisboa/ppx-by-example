project_name = ppx-by-example

DUNE = opam exec -- dune
opam_file = $(project_name).opam

.PHONY: help
help:
	@echo "";
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: build-dev
dev:
	$(DUNE) build -w @all

.PHONY: clean
clean: ## Clean artifacts
	$(DUNE) clean

.PHONY: exec
exec: ## Run the project
	$(DUNE) exec $(demo)

.PHONY: format
format: 
	DUNE_CONFIG__GLOBAL_LOCK=disabled $(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check:
	$(DUNE) build @fmt

.PHONY: create-switch
create-switch: ## Create opam switch
	opam switch create . 5.1.1 --deps-only --with-test -y

.PHONY: install
install:
	$(DUNE) build @install
	opam install . --deps-only --with-test
	cd demo && yarn install

.PHONY: init
init: create-switch install

.PHONY: $(TARGET)
demo-%: 
	DUNE_CONFIG__GLOBAL_LOCK=disabled opam exec -- dune exec $*_demo
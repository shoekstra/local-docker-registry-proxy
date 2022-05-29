MAKEFLAGS := -s
MKCERT_CA_ROOT := $(shell mkcert -CAROOT)
REQUIRED_BINS := mkcert docker-compose

.DEFAULT_GOAL := help

.PHONY: check-deps create-certs start stop restart logs help

check-deps: ## Checks all required dependencies are installed
	$(foreach bin,$(REQUIRED_BINS),\
		$(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))

create-certs: check-deps ## Create required certificate
ifeq (,$(wildcard services/traefik/certs/*.pem))
	@echo "==> Creating *.local certificate..."
	@mkcert "*.local"
	@mv _wildcard.local-key.pem _wildcard.local.pem services/traefik/certs/
	@cp "$(MKCERT_CA_ROOT)"/* services/traefik/certs/
endif

start: check-deps create-certs ## Start local docker registries
	@echo "==> Starting local docker registry..."
	@docker-compose -f docker-compose.yml -f docker-compose-local-registry.yml up -d

stop: check-deps ## Stop local docker registries
	@echo "==> Stopping local docker registry..."
	@docker-compose -f docker-compose.yml -f docker-compose-local-registry.yml down

restart:
	@echo "==> Restarting local docker registry..."
	@docker-compose -f docker-compose.yml -f docker-compose-local-registry.yml restart

logs: check-deps ## Show logs of local repository containers
	@docker-compose -f docker-compose.yml -f docker-compose-local-registry.yml logs -f

help:
	@grep -h -E '^[0-9a-z/A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

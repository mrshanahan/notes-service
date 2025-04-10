.DEFAULT_GOAL := build

DEPLOY_ARGS =?

build:
	$(CURDIR)/scripts/build.sh

deploy:
	$(CURDIR)/scripts/deploy.sh $(DEPLOY_ARGS)

restart-service:
	$(CURDIR)/scripts/restart-service.sh

.PHONY: build deploy restart-service

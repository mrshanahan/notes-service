.DEFAULT_GOAL := build

build:
	$(CURDIR)/scripts/build.sh

deploy:
	$(CURDIR)/scripts/deploy.sh && $(CURDIR)/scripts/restart-service.sh

.PHONY: build deploy

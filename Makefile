.DEFAULT_GOAL := build

build:
	$(CURDIR)/scripts/build.sh

deploy:
	$(CURDIR)/scripts/deploy.sh

clean:
	rm *.tar.gz

.PHONY: build deploy clean

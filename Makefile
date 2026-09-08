.DEFAULT_GOAL := help

.PHONY: help setup up down restart clean distclean settings db-update \
	extension extension-update seed logs shell run jobs

ADMIN_PASSWORD := UbuntuWiki2026!
PORT := $(or $(UBUNTU_MINERVA_PORT),8082)
export UBUNTU_MINERVA_PORT

COMPOSE := docker compose
MW := $(COMPOSE) exec mediawiki
MW_T := $(COMPOSE) exec -T mediawiki

define EXTENSION_SETUP
export COMPOSER_ALLOW_SUPERUSER=1; \
command -v composer >/dev/null 2>&1 || { \
	php -r "copy(\"https://getcomposer.org/installer\", \"/tmp/composer-setup.php\");" && \
	php -r "copy(\"https://composer.github.io/installer.sig\", \"/tmp/composer-setup.sig\");" && \
	php -r "if (hash_file(\"sha384\", \"/tmp/composer-setup.php\") !== trim(file_get_contents(\"/tmp/composer-setup.sig\"))) { fwrite(STDERR, \"ERROR: Invalid Composer installer signature. Aborting.\\n\"); exit(1); }" && \
	php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet && \
	rm -f /tmp/composer-setup.php /tmp/composer-setup.sig; \
}; \
command -v unzip >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq unzip; }; \
if [ -f composer.lock ]; then \
	composer update ubuntu/mediawiki-ubuntu-extension --with-all-dependencies --no-interaction --no-progress; \
else \
	composer update --no-interaction --no-progress; \
fi
endef

## help: Show this help (default target)
help:
	@echo "Usage: make <target>"
	@awk '/^### / { printf "\n%s:\n", substr($$0, 5); next } /^## [a-zA-Z_-]+: / && !/^## help:/ { line = substr($$0, 4); i = index(line, ": "); printf "  %-18s %s\n", substr(line, 1, i - 1), substr(line, i + 2) }' $(MAKEFILE_LIST)
	@echo ""

### Lifecycle

## setup: Create and initialize the wiki from scratch (installs MediaWiki)
setup: up
	@echo "Waiting for database..."
	@until $(MW_T) bash -c "php -r \"new mysqli('db', 'mediawiki', 'mediawiki', 'mediawiki');\"" > /dev/null 2>&1; do printf '.'; sleep 2; done
	@echo " ready."
	$(MW) php maintenance/run.php install \
		--dbtype mysql --dbserver db --dbname mediawiki \
		--dbuser mediawiki --dbpass mediawiki \
		--pass '$(ADMIN_PASSWORD)' \
		"Ubuntu Minerva test wiki" admin
	$(COMPOSE) cp LocalSettings.php mediawiki:/var/www/html/LocalSettings.php
	$(MAKE) --no-print-directory db-update
	$(MAKE) --no-print-directory seed
	@echo ""
	@echo "Setup complete!"
	@echo "  URL:      http://localhost:$(PORT)"
	@echo "  Username: admin"
	@echo "  Password: $(ADMIN_PASSWORD)"

## up: Start the containers (installs the UbuntuWiki extension when needed)
up: LocalSettings.php
	$(COMPOSE) up -d
	$(MAKE) --no-print-directory extension
	@until $(MW_T) bash -c "php -r \"new mysqli('db', 'mediawiki', 'mediawiki', 'mediawiki');\"" > /dev/null 2>&1; do sleep 2; done
	@if $(MW_T) bash -c "php -r \"exit((new mysqli('db', 'mediawiki', 'mediawiki', 'mediawiki'))->query('SELECT 1 FROM page LIMIT 1') ? 0 : 1);\"" > /dev/null 2>&1; then \
		$(COMPOSE) cp LocalSettings.php mediawiki:/var/www/html/LocalSettings.php; \
	else \
		echo "Wiki not installed yet; skipping LocalSettings.php copy (run 'make setup')."; \
	fi

## down: Stop and remove the containers
down:
	$(COMPOSE) down

## restart: Restart the containers (down then up)
restart: down up

## clean: Stop the containers and delete the database volume (DESTRUCTIVE)
clean:
	$(COMPOSE) down -v

## distclean: clean plus delete the generated LocalSettings.php (DESTRUCTIVE)
distclean: clean
	rm -f LocalSettings.php

### Content

## seed: Import the test pages from seed/ into the wiki (idempotent)
seed:
	$(MW_T) mkdir -p /tmp/seed
	$(COMPOSE) cp seed/. mediawiki:/tmp/seed/
	$(MW_T) bash -c '\
		php maintenance/run.php importTextFiles \
			--user Admin --summary "Seed test content" --overwrite \
			/tmp/seed/*.txt'
	$(MAKE) --no-print-directory jobs

## jobs: Force-run the MediaWiki job queue
jobs:
	$(MW_T) php maintenance/run.php runJobs

### Configuration

## settings: Copy LocalSettings.php into the container and run the database update
settings: LocalSettings.php
	$(COMPOSE) cp LocalSettings.php mediawiki:/var/www/html/LocalSettings.php
	$(MAKE) --no-print-directory db-update

## db-update: Run the MediaWiki database update script
db-update:
	$(MW_T) php maintenance/run.php update --quick

### UbuntuWiki extension

## extension: Install the UbuntuWiki extension into the container (skips if present)
extension:
	$(MW_T) bash -c '\
		if [ -d extensions/UbuntuWiki ]; then \
			echo "UbuntuWiki extension already installed, skipping."; \
			exit 0; \
		fi; \
		$(EXTENSION_SETUP)'

## extension-update: Force-update the UbuntuWiki extension, even if already installed
extension-update:
	$(MW_T) bash -c '$(EXTENSION_SETUP)'

### Debugging

## logs: Follow the mediawiki container logs (Ctrl-C to stop)
logs:
	$(COMPOSE) logs -f mediawiki

## shell: Open an interactive bash shell in the mediawiki container
shell:
	$(MW) bash

## run: Run a MediaWiki maintenance script, e.g. make run SCRIPT="runJobs --maxjobs 5"
run:
	$(MW_T) php maintenance/run.php $(SCRIPT)

LocalSettings.php:
	cp LocalSettings.example.php LocalSettings.php
	@echo "Created LocalSettings.php from LocalSettings.example.php."

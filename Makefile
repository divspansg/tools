PROJECT=[XXX]
DOMAIN=divspan.net
GIT=divspangit@git.divspan.net
WPCLI=./wp-cli.phar

# Remote folder. Maybe assume this one to be the same as PROJECT
FOLDER=${PROJECT}

MAKEFLAGS += --no-print-directory
all: dev

#######################
### Secondary commands
remote-cmd:
	ssh ${PROJECT}@${PROJECT}.${DOMAIN} ${CMD}

db-snap:
	@${WPCLI} db export "db/$(shell php -r "echo date('c');").sql" --allow-root

db-load:
	@PREV_URL=$$($(MAKE) wp-get-siteurl); \
	${WPCLI} db import ${DB} --allow-root; \
	if [ "$$PREV_URL" == "" ]; then \
		echo "First DB load. Please adjust the sitename"; \
		echo "Example: FROM=http://localhost:8080 TO=http://www.solasfs.divspan.net/ make wp-replace-url"; \
	else \
		CURR_URL=$$($(MAKE) wp-get-siteurl); \
		if [ "$$PREV_URL" != "$$CURR_URL" ]; then \
			echo "$$PREV_URL got changed to $$CURR_URL. Changing it back"; \
			FROM=$$CURR_URL TO=$$PREV_URL $(MAKE) wp-replace-url; \
			echo "Site URL changed back from $$CURR_URL to $$PREV_URL"; \
		else \
			echo "Loaded site URL is the same than before ($$PREV_URL). Nothing to do"; \
		fi; \
	fi

wp-get-siteurl:
	@${WPCLI} option get siteurl

wp-replace-url:
	@${WPCLI} search-replace "${FROM}" "${TO}" --all-tables --allow-root

##########################
### Everyday commands:
db-latest:
	@LATESTDB=db/$$(ls db/ | col | tail -1); \
	echo Loading latest DB snapshot: $$LATESTDB; \
	DB=$$LATESTDB $(MAKE) db-load

update:
	git pull
	$(MAKE) db-latest

dev:
	php -S localhost:8080

ssh:
	ssh ${PROJECT}@${PROJECT}.${DOMAIN}

ssh-git:
	ssh ${GIT}

# Write down the basic recipe here and expand it in another moment
create:
	wp core download
	#wp core config --dbname={YOUR DATABASE NAME} --dbuser={YOUR DATABASE USERNAME} --dbpass={YOUR DATABASE PASSWORD}
	#wp core install --url={YOUR DOMAIN NAME} --title={THE TITLE OF YOUR SITE} --admin_user={YOUR USER NAME} --admin_password={YOUR PASSWORD} --admin_email={YOUR EMAIL}

info:
	@echo "Remote site URL: ${PROJECT}.${DOMAIN}"

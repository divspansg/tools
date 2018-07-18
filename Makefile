PROJECT=[XXX]
DOMAIN=divspan.net
WPCLI=./wp-cli.phar

# Remote folder. Maybe assume this one to be the same as PROJECT
FOLDER=[XXX]

MAKEFLAGS += --no-print-directory
all: dev

#######################
### Secondary commands
remote-cmd:
	ssh ${PROJECT}@${PROJECT}.${DOMAIN} ${CMD}

db-snap:
	@${WPCLI} db export "db/$(shell date -Iseconds).sql" --allow-root

db-load:
	PREV_URL=$$($(MAKE) wp-get-siteurl); \
	${WPCLI} db import ${DB} --allow-root; \
	if [ "$$PREV_URL" == "" ]; then \
		echo "First DB load. Please adjust the sitename"; \
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

dev:
	php -S localhost:8080

ssh:
	ssh ${PROJECT}@${PROJECT}.${DOMAIN}

# Remote git pull; forces the last installed code to be in git
remote-pull:
	CMD="\"cd ${FOLDER} && git pull\"" $(MAKE) remote-cmd

# Run after working directly in remote, to get a DB copy on git
remote-db-snap:
	# Remote DB snapshot && git commit && git push
	# TODO fix git push. git doesn't ask for repo's user/passwd when is invoked remotelly
	# Also, this can be a bad idea, as there can be conflicts to be solved remotelly. Maybe remote must be read-only
	CMD="\"cd ${FOLDER} && make db-snap && git add db && git commit -m 'DB snapshot' && git push\"" $(MAKE) remote-cmd

# Write down the basic recipe here and expand it in another moment
create:
	wp core download
	#wp core config --dbname={YOUR DATABASE NAME} --dbuser={YOUR DATABASE USERNAME} --dbpass={YOUR DATABASE PASSWORD}
	#wp core install --url={YOUR DOMAIN NAME} --title={THE TITLE OF YOUR SITE} --admin_user={YOUR USER NAME} --admin_password={YOUR PASSWORD} --admin_email={YOUR EMAIL}

info:
	@echo "Remote site URL: ${PROJECT}.${DOMAIN}"

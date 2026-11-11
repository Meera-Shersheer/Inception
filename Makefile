
COMPOSE = docker compose -f srcs/docker-compose.yml
HOST_DATA_PATH := $(shell grep '^HOST_DATA_PATH=' srcs/.env 2>/dev/null | head -n1 | cut -d= -f2)

all: data
	$(COMPOSE) up -d --build


data:
	@test -n "$(HOST_DATA_PATH)" || { echo "Error: HOST_DATA_PATH is missing from srcs/.env"; exit 1; }
	mkdir -p $(HOST_DATA_PATH)/mariadb
	mkdir -p $(HOST_DATA_PATH)/wordpress

build: data
	$(COMPOSE) build

clean:
	$(COMPOSE) down

fclean:
	@test -n "$(HOST_DATA_PATH)" || { echo "Error: HOST_DATA_PATH is missing from srcs/.env"; exit 1; }
	$(COMPOSE) down --rmi all -v
	rm -rf $(HOST_DATA_PATH)/wordpress $(HOST_DATA_PATH)/mariadb

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs

secrets:
	mkdir -p secrets
	@test -s secrets/db_root_password.txt || openssl rand -base64 32 > secrets/db_root_password.txt
	@test -s secrets/db_password.txt || openssl rand -base64 32 > secrets/db_password.txt
	@test -s secrets/wp_admin_password.txt || openssl rand -base64 32 > secrets/wp_admin_password.txt
	@chmod 600 secrets/db_root_password.txt secrets/db_password.txt secrets/wp_admin_password.txt

re: fclean all

.PHONY: all build clean fclean re ps logs secrets
 
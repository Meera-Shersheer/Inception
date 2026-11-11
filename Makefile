
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
	@sudo rm -rf "$(HOST_DATA_PATH)/wordpress" "$(HOST_DATA_PATH)/mariadb"

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs

re: fclean all

.PHONY: all build clean fclean re ps logs

# Developer Documentation

## 1. Introduction

This document explains how to set up, build, run, and manage the Inception project from a development perspective.

The infrastructure consists of three custom Docker images and their corresponding containers:

- **NGINX:** HTTPS entry point and reverse proxy.
- **WordPress:** Website application running with PHP-FPM.
- **MariaDB:** Database server used by WordPress.

All services are built from custom Dockerfiles based on Debian Bookworm Slim and communicate through a dedicated Docker bridge network.

## 2. Prerequisites

The development environment must be configured inside a Debian virtual machine.

Install or prepare the following:

| Requirement | Purpose |
|---|---|
| Debian VM | Environment in which the project runs |
| Docker Engine | Builds and runs containers |
| Docker Compose plugin | Defines and manages the multi-container application |
| GNU Make | Runs the project Makefile |
| OpenSSL | Generates secure passwords and supports certificate generation |
| Git | Retrieves and manages the project source code |

Verify the installations:

```bash
cat /etc/os-release
docker --version
docker compose version
make --version
openssl version
git --version
```

The account running the Makefile must have permission to access the Docker daemon. Configure Docker permissions appropriately before building the project.

## 3. Project Structure

The repository is organized as follows:

```text
Inception/
├── .gitignore
├── Makefile
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            └── tools/
```

The `secrets/` directory is generated and populated by the Makefile if the required files are missing. It must not be committed to the repository.

## 4. Environment Configuration

### 4.1 Environment file

The Compose configuration uses environment variables defined in:

```text
srcs/.env
```

This file contains the non-secret configuration required by the services, including:

- Domain name.
- Database name.
- Database username.
- WordPress administrator username and email.
- Host data directory.

The database host is the MariaDB Compose service name, `mariadb`, allowing WordPress to communicate with the database through Docker's internal DNS.

The host data directory must match the required project storage location:

```dotenv
HOST_DATA_PATH=~/data
```


Do not put actual passwords in the `.env` file. Sensitive credentials are supplied separately through Docker secrets.

To inspect the configured variable names without displaying their values:

```bash
cut -d= -f1 srcs/.env
```

### 4.2 Docker secrets

The project uses three secret files:

| File | Purpose |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | Password for the WordPress database user |
| `secrets/wp_admin_password.txt` | Initial WordPress administrator password |

The Makefile automatically generates any missing secret files using OpenSSL:

```bash
openssl rand -base64 32
```

It also applies restrictive file permissions:

```bash
chmod 600 secrets/db_root_password.txt \
           secrets/db_password.txt \
           secrets/wp_admin_password.txt
```

The secrets are provided to the relevant containers as files under `/run/secrets/`.

**Important security considerations:**

- Never commit the `secrets/` directory.
- Never include secret values in Dockerfiles or source code.
- Do not overwrite existing secrets casually.
- Keep secure backups of the secret files.
- Changing a secret file does not automatically change a password already configured in MariaDB or WordPress. The corresponding application credentials must also be updated.

## 5. Building and Launching the Project

### 5.1 Using the Makefile

The Makefile provides the main interface for managing the infrastructure.

From the repository root:

```bash
make
```

The default target performs the following operations:

1. Applies restrictive permissions to the secret files.
2. Creates the required host data directories.
3. Builds the custom Docker images.
4. Creates and starts the containers in detached mode.

and using:
```bash
make secrets
```

1. Creates the `secrets/` directory if it does not exist.
2. Generates missing secret files.

The equivalent Compose command for building and starting the infrastructure is:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

### 5.2 Available Makefile targets

| Command | Description |
|---|---|
| `make` | Prepares data directories, then builds and starts the project |
| `make all` | Same as `make` |
| `make secrets` | Creates missing secrets and applies permissions |
| `make data` | Creates the persistent host directories |
| `make build` | Builds the Docker images without starting the services |
| `make ps` | Displays the Compose service status |
| `make logs` | Displays service logs |
| `make clean` | Stops and removes containers and the Compose network |
| `make fclean` | Removes containers, images, volumes, and project data |
| `make re` | Performs a full cleanup followed by a fresh build and launch |

**Warning:** `make fclean` is destructive. It removes the persistent WordPress and MariaDB data directories. Back up the data before using it.

## 6. Docker Compose Management

The Compose configuration is located at:

```text
srcs/docker-compose.yml
```

For commands executed directly through Docker Compose, use:

```bash
docker compose -f srcs/docker-compose.yml <command>
```

### 6.1 Validate the configuration

Before launching the project, validate the Compose configuration:

```bash
docker compose -f srcs/docker-compose.yml config
```

This checks and resolves the Compose configuration, including variable interpolation. It does not start containers.

### 6.2 Build and start services

Build all images and start the infrastructure:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

Start existing services without rebuilding:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

Build images without starting containers:

```bash
docker compose -f srcs/docker-compose.yml build
```

### 6.3 Inspect container status

```bash
docker compose -f srcs/docker-compose.yml ps
```

Display all containers, including those that have stopped:

```bash
docker ps -a
```

### 6.4 View logs

Display logs for all services:

```bash
docker compose -f srcs/docker-compose.yml logs
```

Follow logs continuously:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Inspect an individual service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Press `Ctrl+C` to stop following logs. This does not stop the containers.

### 6.5 Execute commands inside containers

Use `docker exec` to inspect or troubleshoot a running container:

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

Run a single command without opening an interactive shell:

```bash
docker exec nginx nginx -t
```

The shell available inside a container depends on the packages installed in its image.

### 6.6 Stop and remove services

Stop and remove the containers and Compose network:

```bash
docker compose -f srcs/docker-compose.yml down
```

This does not remove the persistent named volumes by default.

To rebuild and recreate the services:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

Avoid using `down -v` during ordinary development because it removes the Compose-managed volumes.

## 7. Managing Docker Networks

The project uses a dedicated Docker bridge network named `inception`.

The containers communicate using their Compose service names rather than hardcoded IP addresses:

| Source service | Destination service | Docker DNS name |
|---|---|---|
| NGINX | WordPress | `wordpress` |
| WordPress | MariaDB | `mariadb` |

Inspect available Docker networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect inception
```

Test internal DNS resolution:

```bash
docker exec nginx getent hosts wordpress
docker exec wordpress getent hosts mariadb
```

Only NGINX publishes a port to the host. The application and database services communicate internally through the Docker network.

## 8. Managing Persistent Volumes

The project uses two Docker named volumes to preserve application and database data independently of container lifecycles.

| Compose volume | Container mount point | Host storage directory |
|---|---|---|
| `wordpress_vol` | `/var/www/html` | `~/data/wordpress` |
| `mariadb_vol` | `/var/lib/mysql` | `~/data/mariadb` |

The volumes use Docker's local driver with bind-related driver options. This allows them to remain Docker named-volume objects while storing their data in the required host directories.

NGINX mounts the WordPress volume read-only, while WordPress mounts it read-write. MariaDB mounts its own database volume.

### 8.1 Inspect volumes

List Docker volumes:

```bash
docker volume ls
```

Inspect the project volumes:

```bash
docker volume inspect srcs_wordpress_vol
docker volume inspect srcs_mariadb_vol
```

The `srcs_` prefix comes from the default Compose project name, derived from the Compose project directory.

Inspect the host directories:

```bash
sudo ls -la /home/mshershe/data/wordpress
sudo ls -la /home/mshershe/data/mariadb
```

### 8.2 Data persistence

Container filesystems are not the permanent storage location for the project's application and database data.

The named volumes preserve this data when containers are stopped, removed, or recreated.

For example:

```bash
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d
```

The existing WordPress files and MariaDB database remain available because the host data directories are retained.

### 8.3 Backing up persistent data

Before destructive operations or major changes, back up the persistent data directories.

For example:

```bash
sudo tar -czf inception-data-backup.tar.gz \
    -C /home/mshershe/data wordpress mariadb
```

Store backups securely and outside the directories that may be removed by cleanup operations.

**Important:** `make fclean` removes both host data directories:

```text
~/data/wordpress
~/data/mariadb
```

It also removes the Compose volumes and images. It preserves the secret files, but the application and database data must be restored from a backup if needed.

## 9. Health Checks and Troubleshooting

The Compose configuration includes health checks for MariaDB and WordPress.

Inspect service health:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Inspect a container's health-check details:

```bash
docker inspect mariadb
docker inspect wordpress
```

Check NGINX configuration syntax:

```bash
docker exec nginx nginx -t
```

Test HTTPS access:

```bash
curl -kI https://mshershe.42.fr/
```

The `-k` option allows `curl` to connect despite the self-signed certificate. It is useful for local testing, but it does not establish that the certificate is trusted.

If a service fails to start or becomes unhealthy, inspect its logs first:

```bash
docker compose -f srcs/docker-compose.yml logs --tail=50 mariadb
docker compose -f srcs/docker-compose.yml logs --tail=50 wordpress
docker compose -f srcs/docker-compose.yml logs --tail=50 nginx
```

Check internal service-name resolution if containers cannot communicate:

```bash
docker exec nginx getent hosts wordpress
docker exec wordpress getent hosts mariadb
```

## 10. Development Notes

- Each service has its own Dockerfile and custom image.
- The Docker Compose file defines the services, network, volumes, secrets, and runtime configuration.
- The Makefile provides convenient commands but does not replace Docker Compose.
- Changes to a Dockerfile or files copied into an image generally require rebuilding the corresponding image.
- Changes to persistent application or database data are stored in the host directories through the named volumes.
- Never use `make fclean` as a routine restart command because it deletes persistent data.
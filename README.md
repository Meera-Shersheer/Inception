*This project has been created as part of the 42 curriculum by mshershe*

# Inception
## Description
Inception is a System Administration project from the 42 curriculum. Its goal is to introduce containerization and infrastructure management by building and configuring a small web infrastructure using Docker and Docker Compose.

The infrastructure runs inside a Debian virtual machine and consists of three independent services:

- NGINX: it is the only entry point to the infrastructure and handles HTTPS connections using TLS.

- WordPress: provides the website and runs through PHP-FPM.

- MariaDB: The database that the WordPress utilizes.

Each service runs in its own container, built from a custom Dockerfile based on Debian Bookworm Slim version. The containers communicate through a dedicated Docker bridge network.

Persistent data is stored in two Docker named volumes; one for the MariaDB database and another for the WordPress website files.

The project uses Docker Compose to define and manage the infrastructure, while a root-level Makefile provides commands to build, start, stop, and clean up the application.

<img width="487" height="633" alt="Screenshot From 2026-01-22 13-37-20" src="https://github.com/user-attachments/assets/cc9eb111-e3fc-41e9-95d9-f09ebd4c2094" />

## Instructions

### Prerequisites

The project requires:
- A Debian virtual machine.
- Docker Engine.
- Docker Compose.
- GNU Make.
- Git.
- Root or sudo privileges to run Docker.

### Configuration
Before starting the infrastructure, ensure that the configuration and secret files are present.
####  Environment configuration
The environment configuration is stored in:
```bash
srcs/.env
```
It contains non-confidential settings such as:
```bash
DOMAIN_NAME

MYSQL_DATABASE

MYSQL_USER

HOST_DATA_PATH
```
#### confidential values configuration
Passwords and other confidential values are stored separately in:
```bash
secrets/
```
The required secret files are:
```bash
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
wp_user_password.txt
```
The Makefile generates missing secret files and preserves existing ones. These files must not be committed to Git.

#### Domain configuration

The website uses the domain:

```text
mshershe.42.fr
```

For local access, the domain must resolve to the virtual machine's local IP address.

For a local setup where the browser runs inside the VM, the following entry can be added to /etc/hosts:

```bash
sudo nano /etc/hosts
```

Add: 
```bash
<VM_IP>  <login>.42.fr
```

For Example:
```bash
127.0.0.1 mshershe.42.fr
```
If the browser runs outside the VM, the domain must instead resolve to the VM's reachable IP address.

### Build and launch

From the repository root, run:
```bash
make
```
This prepares the secret files and host data directories, then builds the Docker images and starts the services in detached mode.

To build the images without starting the services:
```bash
make build
```

### Accessing the website
Once the containers are running, access the website through:
```bash
https://mshershe.42.fr
```

The WordPress administration panel is available at:
```bash
https://mshershe.42.fr/wp-admin
```

The project uses a self-signed TLS certificate, so the browser may display a security warning. This is expected in the local development environment.

### Managing the Infrastructure

The root Makefile provides the following commands:

| Command | Description |
|---|---|
| `make` | Creates required directories and secrets, builds images, and starts the stack |
| `make build` | Builds the Docker images |
| `make clean` | Stops and removes containers and the Compose network while preserving persistent data |
| `make fclean` | Removes containers, images, Docker volumes, and host persistent data |
| `make re` | Performs a full cleanup and rebuild |
| `make ps` | Displays the status of the Compose services |
| `make logs` | Displays service logs |
| `make data` | Build the directories that the database would store in |
| `make secrets` | Create the credentials if not available |

**Warning:** `make fclean` is destructive. It deletes the persistent WordPress and MariaDB data stored under data directories. Back up any important data before using it. 


```bash
docker compose -f srcs/docker-compose.yml ps
```

To follow the logs:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

To stop the infrastructure without deleting persistent data:

```bash
docker compose -f srcs/docker-compose.yml down
```

### Testing and Verification

The following checks can be used to verify the infrastructure.

### Check container status

```bash
docker compose -f srcs/docker-compose.yml ps
```

The three services should be running. MariaDB and WordPress should report healthy status when their health checks pass.

### Check Docker network connectivity

Verify that the containers can resolve each other's service names:

```bash
docker exec nginx getent hosts wordpress
docker exec wordpress getent hosts mariadb
```

### Check HTTPS access

```bash
curl -kI https://mshershe.42.fr/
```

The `-k` option allows `curl` to connect despite the self-signed certificate.

### Check NGINX configuration

```bash
docker exec nginx nginx -t
```

This checks the NGINX configuration syntax.

### Check persistent storage

Inspect the named volumes:

```bash
docker volume ls
```

Inspect their configuration:

```bash
docker volume inspect srcs_wordpress_vol
docker volume inspect srcs_mariadb_vol
```


The volume configuration should point to the corresponding directories under ~/data.

To test persistence, stop and recreate the containers without removing the volumes:

```bash
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d
```

The website and database data should remain available after the containers are recreated.

## Resources

- NGINX docs — `location` directive (core module)  
  https://nginx.org/en/docs/http/ngx_http_core_module.html#location
- WordPress Developer Docs — WP-CLI commands  
  https://developer.wordpress.org/cli/commands/

- Docker Docs — Compose file reference (`init`)  
  https://docs.docker.com/reference/compose-file/#init

- Semaphore — *Docker secrets management*  
  https://semaphore.io/blog/docker-secrets-management

- MariaDB Docs — *ACID & concurrency control with transactions*  
  https://mariadb.com/docs/general-resources/database-theory/acid-concurrency-control-with-transactions




### AI Usage
AI tools were used as learning and development assistants throughout the project.
It was used  for discussing architectural decisions.

Also it was used for reviewing Dockerfiles, Docker Compose configurations, NGINX configurations, and service startup scripts and the multiple approuches used to achieve a single functionality.


## Project description
Docker and the project architecture

Docker is used to package each service and its dependencies into an isolated container. Instead of installing and configuring NGINX, PHP-FPM, WordPress, and MariaDB directly on the host operating system, each component runs in its own container.

This separation makes the infrastructure easier to configure, manage, reproduce, and troubleshoot.

The project contains custom Dockerfiles for all three services. These Dockerfiles define the required packages, configuration files, and startup behavior. Docker Compose builds the images and coordinates the containers, network, volumes, and secrets.

### Structure
The repository is organized as follows:

```text
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
```


The `srcs/` directory contains the Docker Compose configuration, environment variables, Dockerfiles, service configurations, and startup scripts.

The `secrets/` directory contains confidential values used by the services. These files are stored locally and excluded from version control.

The Makefile is located at the repository root and manages the infrastructure.

NGINX is the only service exposed to the host through port `443` . It terminates HTTPS connections and forwards PHP requests to the WordPress container through PHP-FPM.

WordPress communicates with MariaDB using the service name mariadb, which is resolved through Docker's internal DNS on the shared bridge network.

The WordPress files are shared between the WordPress and NGINX containers. WordPress has read/write access, while NGINX mounts the website files as read-only.
### Services

| Service | Responsibility | Internal communication |
|---|---|---|
| **NGINX** | HTTPS entry point and reverse proxy | Forwards PHP requests to `wordpress:9000` |
| **WordPress** | Website and PHP execution | Connects to MariaDB |
| **MariaDB** | Persistent relational database | Receives connections from WordPress |

Each service has its own Dockerfile and image. The image names match their corresponding Compose service names: `nginx`, `wordpress`, and `mariadb`.

### Persistent storage

The infrastructure uses two Docker named volumes:

| Named volume | Host storage path | Container storage path |
|---|---|---|
| `wordpress_vol` | `~/data/wordpress` | `/var/www/html` |
| `mariadb_vol` | `~/data/mariadb` | `/var/lib/mysql` |

These are Docker named volumes configured with the local volume driver and bind options. The services use the named volumes rather than declaring direct bind mounts.

This ensures that website files and database contents persist independently of the lifecycle of the containers.


### Project structure

The repository is organized as follows:

Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/

The srcs/ directory contains the Docker Compose configuration, environment variables, Dockerfiles, service configurations, and startup scripts.

The secrets/ directory contains confidential values used by the services. These files are stored locally and excluded from version control.

The Makefile is located at the repository root and manages the infrastructure.

### Virtual Machines vs Docker

A virtual machine virtualizes an entire operating system. It runs its own kernel and operating system environment on top of a hypervisor. This provides strong isolation but requires more resources because each virtual machine runs a complete operating system.

Docker containers share the host machine's kernel while isolating applications and their dependencies. They are generally lighter and faster to start because they do not need a separate operating system.

| Virtual Machines | Docker Containers |
|---|---|
| Virtualize an entire operating system | Isolate applications and their dependencies |
| Each VM has its own kernel | Containers share the host kernel |
| Generally require more resources | Generally have lower overhead |
| Usually slower to start | Usually faster to start |
| Provide operating-system-level isolation | Provide process and resource isolation |

- Choice in this project: The subject requires the infrastructure to run inside a virtual machine, while Docker is used inside that VM to run the individual services. This combines the isolation of a dedicated development environment with the lightweight deployment of containers.

### Secrets vs Environment Variables

Environment variables provide a convenient way to configure applications without hardcoding values into Dockerfiles or application code. They are suitable for configuration values such as domain names, database names, and usernames.

However, environment variables are not ideal for confidential information such as passwords because they can be exposed through process environments, container inspection, or diagnostic output.

Docker secrets provide a mechanism for supplying sensitive information to containers as files, typically mounted under `/run/secrets/`.

| Environment Variables | Docker Secrets |
|---|---|
| Used for application configuration | Used for sensitive information |
| Values are passed through the container environment | Values are mounted as files |
| Convenient for non-confidential settings | Better suited to passwords and credentials |
| May be exposed through environment inspection | Avoids placing secret values directly in environment variables |

- Choice in this project: The `.env` file stores non-confidential configuration values. Passwords are stored in separate files under `secrets/` and supplied to the appropriate services through Docker Compose secrets.

### Docker Network vs Host Network

Docker provides different networking modes for containers.

A bridge network creates an isolated network in which containers can communicate with each other. Docker also provides internal DNS resolution, allowing services to reach one another using their service names.

Host networking removes the usual network isolation between the container and the host. The container shares the host's network namespace.

| Docker Bridge Network | Host Network |
|---|---|
| Provides an isolated container network | Shares the host network namespace |
| Containers can communicate through service names | Uses the host's network interfaces directly |
| Supports Docker-managed network isolation | Reduces network isolation |
| Ports can be selectively published | Containers use host network ports directly |

- Choice in this project: A dedicated Docker bridge network named inception connects NGINX, WordPress, and MariaDB. This allows internal communication without exposing database or PHP-FPM ports to the host.

Only NGINX publishes port `443`.

### Docker Volumes vs Bind Mounts

Both Docker volumes and bind mounts allow data to persist outside a container's writable layer.

Docker volumes are managed by Docker and can be reused by containers. Their storage location and lifecycle are managed through Docker.

Bind mounts directly map a host filesystem path into a container. They provide direct access to host files and directories but depend on the host's directory structure and permissions.

| Docker Volumes | Bind Mounts |
|---|---|
| Managed by Docker | Directly reference host paths |
| Can be reused by multiple containers | Can also be shared between containers |
| Support Docker volume drivers and options | Use an explicitly specified host path |
| Decouple container configuration from the host directory structure | Depend directly on host filesystem paths |

- Choice in this project: The subject requires Docker named volumes for the WordPress files and database. Therefore, the project defines wordpress_vol and mariadb_vol as named volumes and configures their local driver options to store the data under /home/mshershe/data.
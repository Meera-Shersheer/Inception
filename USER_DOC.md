# User Documentation

## 1. Introduction

This document explains how to use and manage the Inception infrastructure. It is intended for users and administrators who need to start or stop the services, access the website, manage credentials, and check that the infrastructure is working correctly.

The project runs inside a Debian virtual machine and consists of three Docker services.

## 2. Services Provided

The infrastructure provides the following services:

| Service | Description |
|---|---|
| **NGINX** | Handles incoming HTTPS connections and forwards requests to WordPress. It is the only service accessible from outside the Docker network. |
| **WordPress** | Hosts the website and provides the administration interface. It runs using PHP-FPM. |
| **MariaDB** | Stores the website's database, including WordPress content, user accounts, and settings. |

The services communicate through an internal Docker network. Website files and database contents are stored in persistent Docker named volumes, so they remain available when containers are stopped or recreated.

## 3. Starting the Project

### Prerequisites

Before starting the project, ensure that:

- The Debian virtual machine is running.
- Docker Engine and Docker Compose are installed.
- The project repository is available on the virtual machine.
- The `.env` configuration file and required secret files are present.
- `make` package installed

### Start the infrastructure

Open a terminal, navigate to the project root directory, and run:

```bash
make
```

The Makefile:

1. Creates any missing secret files (with `make secrets` only).
2. Creates the host directories required for persistent storage.
3. Builds the Docker images.
4. Starts the three services in detached mode.

Once the containers have started, the website should be accessible through the configured domain.

## 4. Accessing the Website

The website is available at:

**https://mshershe.42.fr**

The WordPress administration panel is available at:

**https://mshershe.42.fr/wp-admin**

Use the WordPress administrator credentials to sign in.

### TLS certificate warning

The project uses a self-signed TLS certificate for HTTPS. Because it is not issued by a publicly trusted Certificate Authority, the browser may display a security warning.

This is expected in this local development environment. Verify that you are accessing the intended local website before proceeding.

### Domain resolution
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

## 5. Managing Credentials

Credentials are stored locally in the repository's `secrets/` directory. They are supplied to the relevant containers through Docker Compose secrets.

The required files are:

| File | Purpose |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root account password |
| `secrets/db_password.txt` | Password for the WordPress database user |
| `secrets/wp_admin_password.txt` | Initial WordPress administrator password |

The WordPress administrator username is configured as `meera`.

### Important security considerations

- Never share passwords or expose their contents in screenshots, logs, or public repositories.
- Do not commit the `secrets/` directory to Git.
- Keep a secure backup of credentials if they need to be recovered later.
- The Makefile generates missing secret files and preserves existing ones. Running `make` again does not intentionally replace existing credentials.

### Changing credentials

WordPress administrator credentials can be managed through the WordPress administration panel.

The initial administrator password is supplied during the first WordPress installation. Changing the contents of `wp_admin_password.txt` later does not automatically change the password of an already-created WordPress account.

Database passwords require additional care. Changing `db_password.txt` or `db_root_password.txt` alone does not update the corresponding MariaDB account or the existing WordPress database configuration. The database account and application configuration must be updated consistently.

## 6. Stopping the Project

To stop the infrastructure without deleting persistent website or database data, run the following command from the project root:

```bash
make clean
```

This stops and removes the containers and the Compose network while preserving the named volumes and their data.

To start the infrastructure again, run:

```bash
make
```

### Removing all project data

The following command performs a full cleanup:

```bash
make fclean
```

**Warning:** This command is destructive. It removes the containers, project images, Docker volumes, and persistent website and database data stored under:

```text
/home/mshershe/data/
```

The secret files are preserved, but the WordPress website and database contents are deleted. Back up any important data before running this command.

## 7. Checking the Services

Administrators can use the following commands to check the status of the infrastructure.

### Check container status

From the project root, run:

```bash
make ps
```

Alternatively:

```bash
docker compose -f srcs/docker-compose.yml ps
```

The output displays the state of the three services.

MariaDB and WordPress have health checks configured. Their status should report `healthy` when the corresponding checks pass.

### View service logs

To display the service logs:

```bash
make logs
```

To follow the logs continuously:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

To inspect a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Press `Ctrl+C` to stop following the logs. This does not stop the containers.

### Check website accessibility

Run:

```bash
curl -kI https://mshershe.42.fr/
```

A successful response should include an HTTP status such as `200 OK`.

The `-k` option allows the request to proceed despite the self-signed TLS certificate.

### Check service connectivity

The containers communicate through Docker's internal network. Their service names should resolve correctly.

To check connectivity:

```bash
docker exec nginx getent hosts wordpress
docker exec wordpress getent hosts mariadb
```

If the commands return IP addresses, Docker's internal DNS resolution is working for those services.

### Check NGINX configuration

To test the NGINX configuration:

```bash
docker exec nginx nginx -t
```

A successful test reports that the configuration syntax is valid.

## 8. Persistent Data

The infrastructure stores its data in two Docker named volumes:

| Volume | Host directory | Purpose |
|---|---|---|
| `wordpress_vol` | `~/data/wordpress` | WordPress website files |
| `mariadb_vol` | `~/data/mariadb` | MariaDB database files |

These directories are located on the virtual machine and are used by Docker to preserve data independently of the containers.

Stopping or recreating the containers does not delete this data. However, running `make fclean` removes it.


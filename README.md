# Paymenter Auto-Installer

This repository provides a one-time-use bash script to automatically install and configure Paymenter.
It sets up all required dependencies, database, PHP environment, Redis, Nginx, and more.
Don't ask Corwin or the Paymenter discord for any issues with this installer, this is not Official!

## Features
- Installs PHP 8.3, MariaDB 10.11, Redis, Composer, and Nginx
- Configures a Paymenter database and user
- Sets up Paymenter application files and environment
- Runs database migrations and seeds
- Creates a systemd service for queue workers
- Configures Nginx for non-SSL or SSL
- Sets up a cron job for Laravel schedule

## Requirements
- Ubuntu/Debian-based Linux distribution
- Root or sudo access
- Internet connection
- curl installed

## One-Line Installer
To install Paymenter automatically, run this command:
```bash
command -v curl >/dev/null 2>&1 || { echo "curl is required. Please install it first."; exit 1; }; bash <(curl -sSL https://raw.githubusercontent.com/QKing-Official/Paymenter-Installer/main/installer.sh)
```
This will:
1. Check that curl is installed.
2. Download the latest installer script from GitHub.
3. Execute the installation automatically.

## After Installation
- Paymenter will be accessible at:
  http://your-domain-or-ip
- The queue worker will run as a systemd service (paymenter.service)
- Cron job is set to run Laravel scheduler every minute

## Notes
- The script currently configures Nginx for non-SSL only. For SSL you can use the ssl option in the installer (Use at your own risk!)
- This script is intended to be run only once. Re-running may cause issues.
- Full credits too [Paymenter](https://github.com/Paymenter/Paymenter), Corwin and all other contributors of Paymenter.

## License
Use this script at your own risk. By running it, you agree to the QKOL v3.0 license.

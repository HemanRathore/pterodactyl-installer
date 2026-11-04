<div align="center">

```text
 ███╗   ███╗ █████╗ ██████╗  █████╗ ██████╗  █████╗  ██████╗ █████╗ ██╗     ██╗   ██╗████████╗██╗ █████╗ ███╗  ██╗
 ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██║     ██║   ██║╚══██╔══╝██║██╔══██╗████╗ ██║
 ██╔████╔██║██║  ██║██████╔╝███████║██║  ██║██║  ██║╚█████╗ ██║  ██║██║     ██║   ██║   ██║   ██║██║  ██║██╔██╗██║
 ██║╚██╔╝██║██║  ██║██╔══██╗██╔══██║██║  ██║██║  ██║ ╚═══██╗██║  ██║██║     ██║   ██║   ██║   ██║██║  ██║██║╚████║
 ██║ ╚═╝ ██║╚█████╔╝██║  ██║██║  ██║██████╔╝╚█████╔╝██████╔╝╚█████╔╝███████╗╚██████╔╝   ██║   ██║╚█████╔╝██║ ╚███║
 ╚═╝     ╚═╝ ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚════╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝    ╚═╝   ╚═╝ ╚════╝ ╚═╝  ╚══╝
```

# 🚀 MoradoSolution — Pterodactyl Master Command

**A complete Pterodactyl installer & management tool. One command. Everything included.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v4.5.0-blue.svg)](https://github.com/HemanRathore/pterodactyl-installer/releases)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel%20%2B%20Wings-green.svg)](https://pterodactyl.io)

🌐 **[moradosolution.com](https://moradosolution.com)** • 💬 **[discord.gg/moradosolution](https://discord.gg/moradosolution)**

</div>

---

## ⚡ One-Tap Install

Run the following command as `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)
```

The launcher downloads the latest MoradoSolution installer and starts the management menu.

> **Supported:** Ubuntu 22.04 / 24.04 / 26.04 and Debian 11 / 12 / 13.

---

# ✨ What's Inside

## 🚀 Installation

| Option | Description |
|--------|-------------|
| `[1]` Install Panel | Nginx + Let's Encrypt SSL, Cloudflare Tunnel, or HTTP only |
| `[2]` Install Wings | Docker + latest Wings + optional automatic Let's Encrypt TLS |
| `[3]` Install Combined | Panel + Wings on the same server |

## 🗑️ Uninstallation

| Option | Description |
|--------|-------------|
| `[4]` Uninstall Panel | Removes Panel, database, Nginx configuration and cron |
| `[5]` Uninstall Wings | Removes Wings binary and systemd service |
| `[6]` Uninstall Everything | Full removal of Panel + Wings + Docker + Cloudflared |

## 🔄 Updates

| Option | Description |
|--------|-------------|
| `[7]` Update Panel | Downloads the latest Panel release and runs migrations |
| `[8]` Update Wings | Downloads the latest Wings binary |
| `[9]` Update Both | Updates Panel and Wings |
| `[22]` Safe Update All | Confirms, backs up Panel files/database, then updates APT packages, Panel, and Wings |

Option `[22]` uses `apt-get upgrade` without intentionally removing packages.
It stages and validates Panel files and Composer dependencies before switching,
keeps a root-only Panel/database backup, and retains a Wings binary backup for
rollback if the updated service does not start. Service restarts may occur.

## 🛠️ Fix & Management

| Option | Description |
|--------|-------------|
| `[10]` Fix Panel | Permissions, Nginx, Redis, database credentials, migrations and Composer |
| `[11]` Fix Wings | Restart, reconfigure and repair Docker networking |
| `[12]` Blueprints Manager | Install, update and remove Blueprint Framework extensions |
| `[13]` Eggs Manager | Import eggs and clone supported egg repositories |
| `[14]` SSL Manager | Issue, renew and revoke Let's Encrypt certificates |
| `[15]` Cloudflare Tunnels | Token-based Cloudflare Tunnel management |
| `[16]` Status & Health | Service status, disk, RAM, CPU and software versions |
| `[17]` Backup & Restore | Full, database and file backup/restore management |
| `[18]` Reset Admin Password | Reset the Panel administrator password |
| `[19]` Database Manager | Database information and database management |
| `[20]` Emergency 502 Fix | Automatic package recovery and Nginx/PHP-FPM repair |
| `[21]` 🎨 Themes & Blueprints | Theme and Blueprint management |

---

# 🎨 MoradoSolution Blueprint Pack

MoradoSolution supports Blueprint Framework extensions and theme packages through the built-in Blueprint manager.

| # | Blueprint | Description |
|---|-----------|-------------|
| 1 | `nebula.blueprint` | 🎨 Nebula Theme |
| 2 | `euphoriatheme.blueprint` | 🎨 Euphoria Theme |
| 3 | `BetterAdmin.blueprint` | 🛠️ Better Admin UI |
| 4 | `blueannoucements.blueprint` | 📢 Announcements |
| 5 | `bluetables.blueprint` | 📋 Blue Tables UI |
| 6 | `consolelogs.blueprint` | 🖥️ Console Log Viewer |
| 7 | `dbedit.blueprint` | 🗄️ Database Editor |
| 8 | `huxregister.blueprint` | 📝 Custom Registration |
| 9 | `laravellogs.blueprint` | 📄 Laravel Logs |
| 10 | `loader.blueprint` | ⚡ Loading Screen |
| 11 | `lyrdyannounce.blueprint` | 📣 Announcement System |
| 12 | `mclogs.blueprint` | 📜 mclo.gs Log Upload |
| 13 | `mcmods.blueprint` | 🧩 Minecraft Mod Manager |
| 14 | `mcplugins.blueprint` | 🔌 Minecraft Plugin Manager |
| 15 | `mctools.blueprint` | 🛠️ Minecraft Tools |
| 16 | `minecrafticonchanger.blueprint` | 🖼️ Server Icon Changer |
| 17 | `minecraftplayermanager.blueprint` | 👥 Player Manager |
| 18 | `minecraftpluginmanager.blueprint` | 🔧 Minecraft Plugin Manager |
| 19 | `nightadmin.blueprint` | 🌙 Dark Admin UI |
| 20 | `playerlisting.blueprint` | 📋 Player Listing |
| 21 | `resourcemanager.blueprint` | 📦 Resource Manager |
| 22 | `sagaautosuspension.blueprint` | ⏸️ Automatic Server Suspension |
| 23 | `sagaminecraftmodpackinstaller.blueprint` | 📦 Modpack Installer |
| 24 | `sagaminecraftplayermanager.blueprint` | 👥 Saga Player Manager |
| 25 | `sagaminecraftplugininstaller.blueprint` | 🔌 Saga Plugin Installer |
| 26 | `sagarustplugininstaller.blueprint` | 🦀 Rust Plugin Installer |
| 27 | `sagaserverpropertiesui.blueprint` | ⚙️ Server Properties UI |
| 28 | `sagaserversorter.blueprint` | 🗂️ Server Sorter |
| 29 | `serverbackgrounds.blueprint` | 🖼️ Server Backgrounds |
| 30 | `serverimporter.blueprint` | 📥 Server Importer |
| 31 | `serversplitter.blueprint` | ✂️ Server Splitter |
| 32 | `simplefavicons.blueprint` | ⭐ Custom Favicons |
| 33 | `snowflakes.blueprint` | ❄️ Snowflake Effect |
| 34 | `startupchanger.blueprint` | 🚀 Startup Command Changer |
| 35 | `subdomainmanager.blueprint` | 🌐 Subdomain Manager |
| 36 | `subdomains.blueprint` | 🔗 Subdomain System |
| 37 | `versionchanger.blueprint` | 🔄 Server Version Changer |
| 38 | `votifiertester.blueprint` | 🗳️ Votifier Tester |

---

# 📁 Repository Structure

```text
pterodactyl-installer/
├── install.sh
├── moradosolution-pterodactyl.sh
├── README.md
├── LICENSE
└── blueprints/
    ├── nebula.blueprint
    ├── euphoriatheme.blueprint
    └── ... additional Blueprint files
```

### Main Files

| File | Purpose |
|------|---------|
| `install.sh` | Public one-command installer |
| `moradosolution-pterodactyl.sh` | Main Pterodactyl installation and management script |
| `README.md` | Documentation |
| `LICENSE` | MIT License |
| `blueprints/` | Optional Blueprint files |

---

# 🧩 PHP Compatibility

MoradoSolution includes dynamic PHP runtime detection rather than assuming one fixed PHP version.

The installer manages:

- PHP CLI
- PHP-FPM
- PHP-FPM systemd service
- PHP-FPM socket
- Composer runtime
- Laravel Artisan runtime
- Cron runtime
- Pterodactyl queue worker runtime
- PHP configuration

The installer also checks the Panel's Composer PHP requirements before Panel updates.
Panel installation and updates also require PHP 8.2.35+ or 8.3.36+, the minimum
versions named in the current upstream Panel security release. APT-managed PHP
is upgraded to the newest package available for the selected supported branch
during Panel updates and option `[22]`; source-built PHP is rebuilt from the
latest 8.3 release during Panel updates.

PHP 8.5.12 is the newest PHP release overall, but the current Panel's upstream
Composer requirement is `^8.2 || ^8.3`, which excludes PHP 8.5. The installer
therefore selects the newest compatible branch (PHP 8.3) for fresh installs and
fresh reinstalls, and preserves an existing Panel's configured branch while
upgrading it to the latest available security-patched release.

### Ubuntu 26.04

Ubuntu 26.04 may provide a newer native PHP version than the Panel compatibility target. The installer therefore does **not** blindly select the newest PHP package.

It attempts to use a compatible PHP 8.3/8.2 runtime and provides a PHP 8.3 compatibility fallback when required.

---

# 🖥️ Supported Systems

| Operating System | Version | Status |
|------------------|---------|--------|
| Ubuntu | 22.04 LTS | ✅ Supported |
| Ubuntu | 24.04 LTS | ✅ Supported |
| Ubuntu | 26.04 LTS | ✅ Supported |
| Debian | 11 Bullseye | ✅ Supported |
| Debian | 12 Bookworm | ✅ Supported |
| Debian | 13 Trixie | ✅ Supported |

> PHP repository configuration is selected according to the detected operating-system release.

---

# 🔧 Manual Usage

Download the main installer:

```bash
curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/moradosolution-pterodactyl.sh \
-o /root/moradosolution-pterodactyl.sh
```

Make it executable:

```bash
chmod +x /root/moradosolution-pterodactyl.sh
```

Run it:

```bash
sudo bash /root/moradosolution-pterodactyl.sh
```

---

# 📤 Blueprint Installation

### Method 1 — GitHub Releases

1. Open the repository's **Releases** page.
2. Create a release.
3. Upload the `.blueprint` files as release assets.
4. Configure the Blueprint manager to use the release assets.

### Method 2 — Manual Upload

Upload your Blueprint archive:

```bash
scp Blueprint.rar root@YOUR_SERVER_IP:/root/
```

Then start the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)
```

Select:

```text
[21] Themes & Blueprints
```

---

# ⚙️ Requirements

### Minimum

- Ubuntu or Debian server
- 2 GB RAM
- 20 GB available storage
- Root access
- Internet connectivity

### For SSL

- Domain name pointed to the server
- Port `80` available
- Port `443` available

### Cloudflare Tunnel

Cloudflare Tunnel can be used when direct public exposure of ports `80/443` is not desired.

### Wings node TLS

During Wings installation, enter the node's public FQDN and an email to request a
Let's Encrypt certificate automatically, or leave the hostname blank to skip it.
The hostname must resolve to the node and inbound TCP port 80 must be reachable;
Nginx is stopped briefly if it is active so Certbot's standalone HTTP challenge
can bind that port. Use the same FQDN in the Panel's node settings. After running
the Panel's `wings configure` auto-deploy command, the installer watches for
`/etc/pterodactyl/config.yml`, restarts Wings automatically, and records the
service status in the systemd journal. Check it with
`systemctl status wings --no-pager`.

Panel and Wings downloads use GitHub's latest stable release URLs; Docker's
official install script is fetched at install time, PHP uses the selected
supported branch (and the current stable 8.3 release for the source-build
fallback), and OS packages come from the configured APT repositories.

---

# 🛡️ Recovery & Repair

The installer includes recovery utilities for common Pterodactyl problems.

The emergency recovery system can assist with:

- PHP
- PHP-FPM
- Nginx
- Redis
- Composer
- Laravel permissions
- Panel migrations
- Missing packages
- Panel `502 Bad Gateway`
- Service failures

PHP-dependent services use the detected/configured PHP runtime instead of relying on a fixed PHP-FPM socket.

---

# 🌐 Networking

The installer supports:

- Nginx + HTTP
- Nginx + Let's Encrypt
- Cloudflare Tunnel
- Existing Cloudflare configurations

Make sure DNS records and firewall rules match the deployment method selected during installation.

---

# 🧪 Version

```text
MoradoSolution Pterodactyl Installer
Version: v4.5.0
```

---

# 📞 Support

| Channel | Link |
|---------|------|
| 💬 Discord | https://discord.gg/moradosolution |
| 🌐 Website | https://moradosolution.com |
| 🐛 Issues | https://github.com/HemanRathore/pterodactyl-installer/issues |

---

# 📜 License

This project is licensed under the MIT License.

See [`LICENSE`](LICENSE) for the complete license text.

---

<div align="center">

**Made with ❤️ by [MoradoSolution](https://moradosolution.com)**

*Game Hosting • VPS • Dedicated Servers • Managed Pterodactyl*

</div>

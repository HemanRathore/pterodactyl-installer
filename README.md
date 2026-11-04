<div align="center">

```
███████╗██╗   ██╗███╗   ██╗██████╗  ██████╗██╗      ██████╗ ██╗   ██╗██████╗
╚══███╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║     ██║     ██║   ██║██║   ██║██║  ██║
 ███╔╝    ╚██╔╝  ██║╚██╗██║██╔══██╗██║     ██║     ██║   ██║██║   ██║██║  ██║
███████╗   ██║   ██║ ╚████║██║  ██║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
```

# 🚀 ZynrCloud — Pterodactyl Master Command

**The most complete Pterodactyl installer & management tool. One command. Everything included.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v4.5.0-blue.svg)](https://github.com/HemanRathore/pterodactyl-installer/releases)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel%20%2B%20Wings-green.svg)](https://pterodactyl.io)
[![Discord](https://img.shields.io/discord/YOUR_DISCORD_ID?label=Discord&logo=discord)](https://discord.gg/zynrcloud)

🌐 **[zynr.cloud](https://zynr.cloud)** • 💬 **[discord.gg/zynrcloud](https://discord.gg/zynrcloud)**

</div>

---

## ⚡ One-Tap Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)
```

> Run as **root** on a fresh Ubuntu 22.04/24.04/26.04 or Debian 12/13 server.
> The installer uses a supported PHP 8.2/8.3 release from configured repositories.

---

## ✨ What's Inside

### 🚀 Install
| Option | Description |
|--------|-------------|
| `[1]` Install Panel | Nginx + Let's Encrypt SSL, Cloudflare Tunnel, or HTTP only |
| `[2]` Install Wings | Docker + Wings daemon + auto systemd service |
| `[3]` Install Combined | Panel + Wings on the same server |

### 🗑️ Uninstall
| Option | Description |
|--------|-------------|
| `[4]` Uninstall Panel | Removes panel, DB, nginx config, cron |
| `[5]` Uninstall Wings | Removes Wings binary + service |
| `[6]` Uninstall Everything | Full nuke — Panel + Wings + Docker + Cloudflared |

### 🔄 Update
| Option | Description |
|--------|-------------|
| `[7]` Update Panel | Downloads latest release, runs migrations |
| `[8]` Update Wings | Downloads latest Wings binary |
| `[9]` Update Both | Panel + Wings in one go |
| `[22]` Safe Update All | Backs up Panel files/database, then updates system packages, PHP, Panel, and Wings |

Option `[22]` requires confirmation, creates a root-only Panel file/database backup,
validates the downloaded Panel archive, stages Composer dependencies before switching
Panel files, and backs up the Wings binary before replacement. System updates use
`apt-get upgrade` (no package removals); service restarts may occur. The installer
uses the latest stable Panel/Wings releases rather than pinning a stale version.

### 🛠️ Fix / Manage
| Option | Description |
|--------|-------------|
| `[10]` Fix Panel | Permissions, Nginx, Redis, DB credentials, migrations, Composer |
| `[11]` Fix Wings | Restart, reconfigure, Docker networking fix |
| `[12]` Blueprints Manager | Install/update/remove Blueprint Framework + extensions |
| `[13]` Eggs Manager | Import eggs, clone pelican/parkervcp repos |
| `[14]` SSL Manager | Issue, renew, revoke Let's Encrypt certs |
| `[15]` Cloudflare Tunnels | Token-based tunnel install + management |
| `[16]` Status & Health | All services status, disk/RAM/CPU, versions |
| `[17]` Backup & Restore | Full/DB/files backup + restore |
| `[18]` Reset Admin Password | Via artisan tinker |
| `[19]` Database Manager | Table sizes, node DB users, nuke & recreate |
| `[20]` Emergency 502 Fix | Auto-installs missing packages, rebuilds nginx |
| `[21]` 🎨 Themes & Blueprints | **Nebula theme + 38-blueprint ZynrCloud pack** |

---

## 🎨 ZynrCloud Blueprint Pack (38 extensions)

Upload `Blueprint.rar` to `/root/` on your server, then run option `[21]`.

Or install individual blueprints from the menu — they download automatically from GitHub.

| # | Blueprint | Description |
|---|-----------|-------------|
| 1 | `nebula.blueprint` | 🎨 Nebula Theme — official Pterodactyl theme |
| 2 | `euphoriatheme.blueprint` | 🎨 Euphoria Theme |
| 3 | `BetterAdmin.blueprint` | 🛠️ Better Admin panel UI |
| 4 | `blueannoucements.blueprint` | 📢 Announcements system |
| 5 | `bluetables.blueprint` | 📋 Blue Tables UI redesign |
| 6 | `consolelogs.blueprint` | 🖥️ Console log viewer |
| 7 | `dbedit.blueprint` | 🗄️ Database editor |
| 8 | `huxregister.blueprint` | 📝 Custom register page |
| 9 | `laravellogs.blueprint` | 📄 Laravel logs viewer |
| 10 | `loader.blueprint` | ⚡ Loading screen |
| 11 | `lyrdyannounce.blueprint` | 📣 Lyrdy announcements |
| 12 | `mclogs.blueprint` | 📜 Upload logs to mclo.gs |
| 13 | `mcmods.blueprint` | 🧩 Minecraft mod manager |
| 14 | `mcplugins.blueprint` | 🔌 Minecraft plugin manager |
| 15 | `mctools.blueprint` | 🛠️ Minecraft tools |
| 16 | `minecrafticonchanger.blueprint` | 🖼️ Server icon changer |
| 17 | `minecraftplayermanager.blueprint` | 👥 Player manager |
| 18 | `minecraftpluginmanager.blueprint` | 🔧 Plugin manager |
| 19 | `nightadmin.blueprint` | 🌙 Night/dark admin UI |
| 20 | `playerlisting.blueprint` | 📋 Player listing |
| 21 | `resourcemanager.blueprint` | 📦 Resource manager |
| 22 | `sagaautosuspension.blueprint` | ⏸️ Auto server suspension |
| 23 | `sagaminecraftmodpackinstaller.blueprint` | 📦 Modpack installer |
| 24 | `sagaminecraftplayermanager.blueprint` | 👥 Saga player manager |
| 25 | `sagaminecraftplugininstaller.blueprint` | 🔌 Saga plugin installer |
| 26 | `sagarustplugininstaller.blueprint` | 🦀 Rust plugin installer |
| 27 | `sagaserverpropertiesui.blueprint` | ⚙️ Server properties UI |
| 28 | `sagaserversorter.blueprint` | 🗂️ Server sorter |
| 29 | `serverbackgrounds.blueprint` | 🖼️ Custom server backgrounds |
| 30 | `serverimporter.blueprint` | 📥 Server importer |
| 31 | `serversplitter.blueprint` | ✂️ Server splitter |
| 32 | `simplefavicons.blueprint` | ⭐ Custom favicons |
| 33 | `snowflakes.blueprint` | ❄️ Seasonal snowflake effect |
| 34 | `startupchanger.blueprint` | 🚀 Startup command changer |
| 35 | `subdomainmanager.blueprint` | 🌐 Subdomain manager |
| 36 | `subdomains.blueprint` | 🔗 Subdomain system |
| 37 | `versionchanger.blueprint` | 🔄 Server version changer |
| 38 | `votifiertester.blueprint` | 🗳️ Votifier tester |

---

## 📁 Repo Structure

```
pterodactyl-installer/
├── install.sh                    ← One-tap public installer (this is what people run)
├── zynrcloud-pterodactyl.sh      ← Main 2800+ line management script
├── README.md
├── LICENSE
└── blueprints/                   ← Upload your .blueprint files here as GitHub Release assets
    ├── nebula.blueprint
    ├── euphoriatheme.blueprint
    └── ... (all 38 .blueprint files)
```

---

## 📤 Uploading Blueprint Files to GitHub

Two ways to make blueprints available:

### Method 1 — GitHub Releases (Recommended)
1. Go to your repo → **Releases** → **Create a new release**
2. Tag it `v1.0.0` (or latest)
3. Drag and drop all `.blueprint` files as **release assets**
4. Users can then install them directly from option `[21]` without uploading anything

### Method 2 — User uploads via SCP
Users upload `Blueprint.rar` to their server:
```bash
scp Blueprint.rar root@YOUR_SERVER_IP:/root/
```
Then run option `[21]` from the script.

---

## 🖥️ Supported Systems

| OS | Version | Status |
|----|---------|--------|
| Ubuntu | 22.04, 24.04, 26.04 | ✅ Supported (PHP 8.2/8.3 only) |
| Debian | 12 (Bookworm), 13 (Trixie) | ✅ Supported (PHP 8.2/8.3 only) |

Pterodactyl and PHP security fixes come from their upstream stable release and
the configured operating-system repositories. Run option `[22]` regularly to
apply available system/PHP package security updates along with Panel and Wings
updates; verify repository package updates are available for the installed PHP
branch before relying on them for a particular advisory.

The current upstream Panel security release identifies PHP 8.2.35 and 8.3.36
as minimum fixed versions for its PHP-related advisory. New installs and Panel
updates refuse to proceed below those levels; use a trusted repository that
provides patched packages if the OS repository has not published them yet.

---

## 🔧 Manual Usage

If you already have the script on your server:

```bash
# Download
curl -fsSL https://raw.githubusercontent.com/zynrcloud/pterodactyl-installer/main/zynrcloud-pterodactyl.sh -o /root/zynrcloud-pterodactyl.sh

# Run
chmod +x /root/zynrcloud-pterodactyl.sh && sudo bash /root/zynrcloud-pterodactyl.sh
```

---

## 📋 Requirements

- Fresh VPS/dedicated server (Ubuntu or Debian)
- Minimum 2GB RAM, 20GB disk
- Root access
- Domain name pointed to server IP (for SSL install)
- Port 80 and 443 open (or Cloudflare Tunnel)

For Cloudflare Tunnel mode, create the tunnel in the Cloudflare dashboard and add
a public hostname for the panel with service `http://localhost:80`. The installer
configures Nginx for that local HTTP origin, installs `cloudflared`, and validates
the token service; it cannot create the Cloudflare dashboard hostname for you.

---

## 📞 Support

| Channel | Link |
|---------|------|
| 💬 Discord | [discord.gg/zynrcloud](https://discord.gg/zynrcloud) |
| 🌐 Website | [zynrcloud.com](https://zynrcloud.com) |
| 🐛 Issues | [GitHub Issues](https://github.com/zynrcloud/pterodactyl-installer/issues) |

---

## 📜 License

MIT License — free to use, modify, and distribute. Attribution appreciated.

---

<div align="center">

**Made with ❤️ by [ZynrCloud](https://zynrcloud.com)**

*Enterprise Game Hosting • VPS • Managed Pterodactyl*

</div>

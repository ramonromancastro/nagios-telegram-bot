# 🤖 Nagios Telegram Bot & Notifier

A complete **ChatOps and Active Notification** ecosystem for Nagios Core, written entirely in pure Bash.

This project empowers you to not only receive real-time Nagios alerts directly on your Telegram account but also to interact bi-directionally with your monitoring server. You can check infrastructure status, view performance metrics, and acknowledge (ACK) incidents directly from your mobile device.

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Bash](https://img.shields.io/badge/Language-Bash-green.svg)

> **🤖 AI-Assisted Development:** This project was architected, refactored, and documented with the assistance of Artificial Intelligence. AI was leveraged to ensure strict adherence to Bash Best Practices (Strict Mode), robust error handling, and modern Linux packaging standards.

## ✨ Key Features

* 🚀 **Zero Heavy Dependencies:** Written in Bash (Strict Mode). No need to install Python, Node.js, or Ruby environments.
* 🛡️ **Native Security Bypass:** Seamless integration with Nagios Core >= 4.2.0, including automatic extraction and validation of CSRF tokens (`nagFormId`) to securely dispatch commands.
* 🔄 **Bi-directional ChatOps:** Receive instant push alerts and execute actions right from your Telegram chat.
* 🧠 **Anti-Alert Fatigue:** The bot intelligently filters out failed services if their parent Host is already down, and ignores incidents that have already been acknowledged (ACK).
* ⚙️ **Enterprise-Ready:** Automated installation via standard `./configure` and `Makefile`, robust Systemd daemon management, and execution with dropped privileges (non-root system user).

## 📦 Prerequisites

Ensure the server hosting your Nagios Core instance has the following basic packages installed:

* `curl` (for HTTP/API requests)
* `jq` (for JSON parsing)
* `awk` (for text and command processing)

## 🛠️ Project Components

This ecosystem consists of two main tools that can work together or independently:

### 1. `nagios-telegram-bot` (The Interactive Daemon)

The core engine (Long-Polling) that listens to your Telegram messages and interacts with the Nagios CGIs (`statusjson.cgi` and `cmd.cgi`).

**Command-line Arguments:**

| Flag | Long Flag | Description | Required |
| :--- | :--- | :--- | :---: |
| `-f` | `--config` | Path to `.env` file (Default `/etc/nagios-telegram-bot/config.env`) | ❌ |
| `-V` | `--version` | Show script version | ❌ |


**Available Telegram Commands:**

* 🖥️ `/hosts` - Show down or unreachable hosts (unacknowledged).
* ⚙️ `/services` - List critical or warning services.
* 📊 `/status` - Display Nagios engine status (notifications, active checks).
* 📈 `/perf` - Show latency, execution times, and check volume metrics.
* 🔕 `/ack_host` - Acknowledge a downed host (e.g., `/ack_host "Server01" "Investigating"`).
* 🔕 `/ack_service` - Acknowledge a failed service (e.g., `/ack_service "Server01" "HTTP" "Network glitch"`).
* 📢 `/broadcast` - Send a mass message to all other authorized bot administrators.
* 🏓 `/ping` - Check bot availability.
* 🛑 `/shutdown` - Cleanly terminate or restart the daemon remotely.
* ℹ️ `/help` - Display the help menu.

### 2. `nagios-telegram-notify` (The Active Notifier)

A script designed to be executed directly by the Nagios notification engine. It formats the alerts and dispatches them to Telegram safely.

**Command-line Arguments:**

| Flag | Long Flag | Description | Required |
| :--- | :--- | :--- | :---: |
| `-c` | `--chat-id` | Target Telegram Chat ID | ✅ |
| `-t` | `--type` | Notification type (`HOST` or `SERVICE`) | ✅ |
| `-H` | `--hostname` | Host name | ✅ |
| `-s` | `--state` | Current state (`UP`, `DOWN`, `OK`, `CRITICAL`...) | ✅ |
| `-o` | `--output` | Plugin output/information | ✅ |
| `-d` | `--description` | Service description | ⚠️ *(If type=SERVICE)* |
| `-k` | `--token` | Bot Token (Overrides config file) | ❌ |
| `-f` | `--config` | Path to `.env` file (Default `/etc/nagios-telegram-bot/config.env`) | ❌ |
| `-v` | `--verbose` | Enable verbose logging (ideal for debugging) | ❌ |
| `-V` | `--version` | Show script version | ❌ |

## 🚀 Installation

The installation process follows standard UNIX/Linux build tree practices.

**1. Clone the repository:**

```bash
git clone [https://github.com/your-username/nagios-telegram-bot.git](https://github.com/your-username/nagios-telegram-bot.git)
cd nagios-telegram-bot
```

**2. Configure the build environment:**

Run the configuration script. It will interactively prompt you for your Telegram tokens and Nagios credentials:

```bash
./configure.sh
```

*(Optional): You can pass all parameters non-interactively for automation: ./configure.sh --bot-token=... --chat-ids=...*

**3. Install globally:**

```bash
sudo make install-all
```

**4. Clean build files (Optional):**

```bash
make clean
```

*Note: To uninstall the software in the future, you can use sudo make uninstall (keeps your configuration and data) or sudo make purge (completely wipes all binaries, configs, and the system user).*

## ⚙️ Nagios Core Configuration

To instruct Nagios to use the notification script automatically, you need to configure your commands and contacts.

**1. Define the Commands (`commands.cfg`):**

```plaintext
define command {
    command_name    notify-host-by-telegram
    command_line    /usr/local/bin/nagios-telegram-notify -c "$_CONTACTTELEGRAM_ID$" -t "HOST" -H "$HOSTNAME$" -s "$HOSTSTATE$" -o "$HOSTOUTPUT$"
}

define command {
    command_name    notify-service-by-telegram
    command_line    /usr/local/bin/nagios-telegram-notify -c "$_CONTACTTELEGRAM_ID$" -t "SERVICE" -H "$HOSTNAME$" -d "$SERVICEDESC$" -s "$SERVICESTATE$" -o "$SERVICEOUTPUT$"
}
```

**2. Assign the Chat ID to a Contact (`contacts.cfg`):**

```plaintext
define contact {
    contact_name                    telegram_admin
    use                             generic-contact
    alias                           Telegram Administrator
    
    service_notification_commands   notify-service-by-telegram
    host_notification_commands      notify-host-by-telegram
    
    # Replace with your actual Telegram Chat ID
    _TELEGRAM_ID                    123456789
}
```

Finally, restart Nagios (`systemctl restart nagios`) to apply the changes.

## 📄 License

This project is licensed under the GNU General Public License v3.0 (GPLv3).

You are free to use, study, share, and modify this software, provided that any derivative work is distributed under this same license and the source code remains open. See the LICENSE file for more details.

# Makefile for Nagios Telegram Bot

# 1. Ahora incluimos el config.mk desde la carpeta build/
-include build/config.mk

ifndef BINDIR
$(error You must run ./configure before making/installing)
endif

.PHONY: all install install-command install-config install-daemoninit install-all clean install-user uninstall purge

all:
	@echo "Build environment is configured."
	@echo "Available targets:"
	@echo "  make install             - Installs the main bot script"
	@echo "  make install-command     - Installs the Nagios notification command"
	@echo "  make install-config      - Installs the configuration file"
	@echo "  make install-daemoninit  - Installs and enables the systemd service"
	@echo "  make install-all         - Installs everything"
	@echo "  make clean               - Removes the build/ directory"
	@echo "  make uninstall           - Removes binaries and service (keeps config/data)"
	@echo "  make purge               - Removes EVERYTHING (binaries, config, data, user)"


install:
	@echo "[INFO] Installing bot script to $(BINDIR)..."
	install -d -m 755 $(BINDIR)
	install -m 755 nagios-telegram-bot $(BINDIR)/

# Regla para crear el usuario del sistema
install-user:
	@echo "[INFO] Verifying system user $(DAEMON_USER)..."
	@id -u $(DAEMON_USER) >/dev/null 2>&1 || \
		(echo "[INFO] Creating system user $(DAEMON_USER)..." && \
		useradd -r -M -s /bin/false $(DAEMON_USER))

install-command:
	@echo "[INFO] Installing notification command script to $(BINDIR)..."
	install -d -m 755 $(BINDIR)
	install -m 755 nagios-telegram-notify $(BINDIR)/

install-config: install-user build/config.env.build
	@echo "[INFO] Installing configuration file to $(SYSCONFDIR)..."
	install -d -m 755 -o $(DAEMON_USER) $(SYSCONFDIR)
	install -m 600 -o $(DAEMON_USER) build/config.env.build $(SYSCONFDIR)/config.env
	@echo "[INFO] Ensuring correct ownership for offset file if it exists..."
	@touch $(SYSCONFDIR)/bot_offset.txt
	@chown $(DAEMON_USER) $(SYSCONFDIR)/bot_offset.txt

install-daemoninit: install-user
	@echo "[INFO] Installing systemd service..."
	install -d -m 755 $(SYSTEMDDIR)
	install -m 644 build/nagios-telegram-bot.service.build $(SYSTEMDDIR)/nagios-telegram-bot.service
	systemctl daemon-reload
	systemctl enable nagios-telegram-bot.service
	systemctl restart nagios-telegram-bot.service

install-all: install install-command install-config install-daemoninit
	@echo "------------------------------------------------"
	@echo "[OK] Nagios Telegram Bot fully installed!"
	@echo "Check service status with: systemctl status nagios-telegram-bot.service"

uninstall:
	@echo "[INFO] Stopping and disabling service..."
	-systemctl stop nagios-telegram-bot.service
	-systemctl disable nagios-telegram-bot.service
	@echo "[INFO] Removing binaries and service unit..."
	rm -f $(BINDIR)/nagios-telegram-bot
	rm -f $(BINDIR)/nagios-telegram-notify
	rm -f $(SYSTEMDDIR)/nagios-telegram-bot.service
	systemctl daemon-reload
	@echo "[OK] Software uninstalled (Configuration kept in $(SYSCONFDIR))"

purge: uninstall
	@echo "[INFO] Removing configuration and data files..."
	rm -rf $(SYSCONFDIR)
	@echo "[INFO] Removing system user $(DAEMON_USER)..."
	-userdel $(DAEMON_USER)
	@echo "[OK] All traces of Nagios Telegram Bot have been removed."

clean:
	@echo "[INFO] Cleaning up build directory..."
	rm -rf build/
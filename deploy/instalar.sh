#!/bin/bash
# Instala el cronómetro como servicio en Red Hat / RHEL 8-9.  Uso: sudo bash deploy/instalar.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST=/opt/cronometro
PORT=8080

command -v python3 >/dev/null || dnf install -y python3

id cronometro >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin cronometro
mkdir -p "$DEST"
cp "$SRC"/server.py "$SRC"/Cron*metro*.html "$DEST"/
touch "$DEST/registros.txt"
chown -R cronometro:cronometro "$DEST"
restorecon -R "$DEST" 2>/dev/null || true

cp "$SRC/deploy/cronometro.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cronometro

if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-port=$PORT/tcp && firewall-cmd --reload
fi

echo "Listo: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "Registros: $DEST/registros.txt"

#!/bin/bash
# Instala el cronómetro como servicio systemd en Ubuntu, Debian o Red Hat.
# Uso: sudo bash deploy/instalar.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST=/opt/cronometro
PORT=8080

if ! command -v python3 >/dev/null; then
  if command -v apt-get >/dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3
  elif command -v dnf >/dev/null; then
    dnf install -y python3
  elif command -v yum >/dev/null; then
    yum install -y python3
  else
    echo "No se encontró un gestor de paquetes compatible para instalar Python 3." >&2
    exit 1
  fi
fi

NOLOGIN="$(command -v nologin || printf '%s' /bin/false)"
id cronometro >/dev/null 2>&1 || useradd --system --no-create-home --shell "$NOLOGIN" cronometro
mkdir -p "$DEST"
cp "$SRC"/server.py "$SRC"/Cron*metro*.html "$DEST"/
touch "$DEST/registros.txt"
chown -R cronometro:cronometro "$DEST"
restorecon -R "$DEST" 2>/dev/null || true

cp "$SRC/deploy/cronometro.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable cronometro
systemctl restart cronometro   # también sirve para actualizar: aplica un server.py nuevo

if command -v firewall-cmd >/dev/null && systemctl is-active --quiet firewalld; then
  if ! firewall-cmd --query-port="$PORT"/tcp >/dev/null; then
    firewall-cmd --permanent --add-port="$PORT"/tcp
    firewall-cmd --reload
  fi
elif command -v ufw >/dev/null && ufw status | grep -q "^Status: active"; then
  ufw allow "$PORT"/tcp
fi

echo "Listo: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "Registros: $DEST/registros.txt"

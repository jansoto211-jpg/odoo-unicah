#!/bin/bash
# Arranque de Odoo para la nube: lee la conexión de DATABASE_URL y genera odoo.conf.
set -euo pipefail

: "${DATABASE_URL:?Falta la variable DATABASE_URL (postgresql://usuario:clave@host:5432/base)}"
: "${ADMIN_PASSWD:?Falta ADMIN_PASSWD (contraseña maestra de Odoo)}"

eval "$(python3 - <<'PY'
import os, shlex
from urllib.parse import urlparse, unquote
u = urlparse(os.environ["DATABASE_URL"])
for k, v in {
    "DB_HOST": u.hostname,
    "DB_PORT": u.port or 5432,
    "DB_USER": unquote(u.username or ""),
    "DB_PASSWORD": unquote(u.password or ""),
    "DB_NAME": u.path.lstrip("/"),
}.items():
    print(f"export {k}={shlex.quote(str(v))}")
PY
)"

CONF=/tmp/odoo.conf
cat > "$CONF" <<CONF
[options]
admin_passwd = ${ADMIN_PASSWD}
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
db_name = ${DB_NAME}
dbfilter = ^${DB_NAME}\$
list_db = False
http_port = ${PORT:-8069}
proxy_mode = True
workers = ${ODOO_WORKERS:-0}
max_cron_threads = ${ODOO_CRON_THREADS:-1}
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
without_demo = True
CONF

ARGS=(-c "$CONF")
# Primera vez con base vacía: ODOO_INIT="base,sale_management,ventas_unicah"
[ -n "${ODOO_INIT:-}" ]   && ARGS+=(-i "$ODOO_INIT")
# Tras cambiar código del módulo: ODOO_UPDATE="ventas_unicah"
[ -n "${ODOO_UPDATE:-}" ] && ARGS+=(-u "$ODOO_UPDATE")

exec odoo "${ARGS[@]}"

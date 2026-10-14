#!/usr/bin/env bash
set -euo pipefail
# Publishes ONLY the static ROOTS website to its dedicated cPanel DocumentRoot.
# No changes to DalyAccounting code, website, databases, credentials or repo.
OWNER='dalypxmu'
ROOT='/home/dalypxmu/admroots.dalyfinanzas.com'
REPO='fabianuhicha-prog/ROOTS'
# Reviewed staging commit: changes to this version require an explicit version update.
COMMIT='da7cd9264151f315b0d1c160e90bbf976ee0b840'
URL="https://codeload.github.com/$REPO/tar.gz/$COMMIT"
[[ "$(id -un)" == "$OWNER" && "$HOME" == "/home/$OWNER" ]] || { echo 'ERROR: ejecuta en el Terminal de cPanel dalypxmu'; exit 1; }
[[ -d "$ROOT" && ! -L "$ROOT" && "$(readlink -f "$ROOT")" == "$ROOT" ]] || { echo 'ERROR: DocumentRoot ROOTS diferente del autorizado'; exit 1; }
[[ "$(stat -c %U "$ROOT")" == "$OWNER" ]] || { echo 'ERROR: propietario del DocumentRoot incorrecto'; exit 1; }
# Deny unreviewed pre-existing content rather than risk overwriting another site.
if find "$ROOT" -mindepth 1 -maxdepth 1 \
 ! -name '.well-known' ! -name 'cgi-bin' ! -name '.roots-web-deploy-approved' \
 ! -name '.htaccess' ! -name 'index.html' ! -name 'robots.txt' \
 ! -name 'productos.json' ! -name 'menu_digital.json' ! -name 'assets' \
 -print -quit | grep -q .; then
 echo 'ERROR: existen archivos no pertenecientes a ROOTS; nada se ha modificado'; exit 1
fi
[[ ! -L "$ROOT/assets" && ! -L "$ROOT/index.html" ]] || { echo 'ERROR: enlace simbólico no permitido'; exit 1; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
chmod 700 "$WORK"
command -v curl >/dev/null && command -v tar >/dev/null || { echo 'ERROR: faltan utilidades curl/tar'; exit 1; }
curl --fail --silent --show-error --location --retry 2 --max-time 90 "$URL" -o "$WORK/release.tar.gz"
tar -tzf "$WORK/release.tar.gz" >/dev/null
mkdir -p "$WORK/unpack"
tar -xzf "$WORK/release.tar.gz" -C "$WORK/unpack" --no-same-owner --no-same-permissions
SRC="$WORK/unpack/ROOTS-$COMMIT/site"
[[ -s "$SRC/index.html" && -s "$SRC/productos.json" && -s "$SRC/menu_digital.json" \
   && -s "$SRC/assets/logo.webp" && -f "$SRC/robots.txt" ]] || { echo 'ERROR: paquete web incompleto'; exit 1; }
grep -q 'ROOTS & ROUTES' "$SRC/index.html" || { echo 'ERROR: identidad web incorrecta'; exit 1; }
BACKUP_DIR="$HOME/.roots_web_backups"; mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
BACKUP="$BACKUP_DIR/pre_manual_$COMMIT-$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP" -C "$ROOT" .
[[ -s "$BACKUP" ]] || { echo 'ERROR: respaldo no verificable'; exit 1; }
if ! cp -a "$SRC/." "$ROOT/"; then
 echo 'ERROR: falló la copia, se restaurarán los archivos anteriores'
 tar -xzf "$BACKUP" -C "$ROOT" || true
 exit 1
fi
# Marker authorizes the regular ROOTS-only GitHub Actions workflow for subsequent updates.
touch "$ROOT/.roots-web-deploy-approved"; chmod 644 "$ROOT/.roots-web-deploy-approved"
echo "ROOTS_PUBLICACION_LOCAL_OK; REVISION=$COMMIT"
echo "ROOTS_RESPALDO=$BACKUP"
echo "URL_PREVISTA=https://admroots.dalyfinanzas.com/"
echo 'Comprueba después la resolución DNS, certificado SSL, enlaces y datos comerciales.'

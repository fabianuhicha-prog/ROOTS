#!/usr/bin/env bash
set -euo pipefail
# Initial, one-time, restricted bootstrap for ROOTS staging only.
# Do not run outside the Namecheap cPanel Terminal belonging to 'dalypxmu'.
ROOT='/home/dalypxmu/admroots.dalyfinanzas.com'
PUB_URL='https://raw.githubusercontent.com/fabianuhicha-prog/ROOTS/staging/deploy/roots_web_staging_ssh.pub'
EXPECTED_SHA256='816e65c6ab62cd18b23b962030219ac4b1e6f9694f48d038dc5d6763454e4eab'
[[ "$(id -un)" == dalypxmu && "$HOME" == /home/dalypxmu ]] || { echo 'ERROR: usuario SSH no autorizado'; exit 1; }
[[ -d "$ROOT" && ! -L "$ROOT" && "$(readlink -f "$ROOT")" == "$ROOT" ]] || { echo 'ERROR: la carpeta ROOTS es inexistente o no es exclusiva'; exit 1; }
[[ "$(stat -c %U "$ROOT")" == dalypxmu ]] || { echo 'ERROR: propietario incorrecto'; exit 1; }
# Refuse to auto-authorize if this folder already hosts an active site.
if find "$ROOT" -mindepth 1 -maxdepth 1 \
  ! -name 'cgi-bin' ! -name '.well-known' ! -name '.roots-web-deploy-approved' -print -quit | grep -q .; then
  echo 'ERROR: hay archivos en la carpeta ROOTS que requieren revisión manual'; exit 1
fi
[[ ! -L "$HOME/.ssh" && ! -L "$HOME/.ssh/authorized_keys" ]] || { echo 'ERROR: ruta SSH enlazada'; exit 1; }
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
curl --fail --silent --show-error --location --max-time 30 "$PUB_URL" > "$TMP"
printf '%s  %s\n' "$EXPECTED_SHA256" "$TMP" | sha256sum -c - >/dev/null || { echo 'ERROR: huella de clave distinta'; exit 1; }
grep -q '^ssh-rsa ' "$TMP" || { echo 'ERROR: tipo de clave inesperado'; exit 1; }
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"; chmod 600 "$HOME/.ssh/authorized_keys"
PUB="$(cat "$TMP")"
if grep -qxF "$PUB" "$HOME/.ssh/authorized_keys"; then
  echo 'La clave pública de ROOTS ya estaba autorizada.'
else
  printf '%s\n' "$PUB" >> "$HOME/.ssh/authorized_keys"
  echo 'Nueva clave pública independiente de ROOTS autorizada.'
fi
touch "$ROOT/.roots-web-deploy-approved"
chmod 644 "$ROOT/.roots-web-deploy-approved"
echo 'ROOTS_CPANEL_PREPARADO:OK'
echo 'No se han modificado archivos del sitio DalyAccounting.'

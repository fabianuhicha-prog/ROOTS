#!/usr/bin/env bash
set -euo pipefail
# Deploy only the previously approved ROOTS static web directory.
HOST="${ROOTS_WEB_SSH_HOST:-}"
USER="${ROOTS_WEB_SSH_USER:-}"
PORT="${ROOTS_WEB_SSH_PORT:-}"
KEY="${ROOTS_WEB_SSH_PRIVATE_KEY:-}"
KNOWN="${ROOTS_WEB_SSH_KNOWN_HOSTS:-}"
[[ "$HOST" == 'business70.web-hosting.com' && "$USER" == 'dalypxmu' && "$PORT" == '21098' ]] || { echo 'Destino SSH diferente del aprobado'; exit 1; }
[[ -n "$KEY" && -n "$KNOWN" ]] || { echo 'Faltan secretos SSH exclusivos de ROOTS'; exit 1; }
COMMIT="${GITHUB_SHA:-}"
[[ "$COMMIT" =~ ^[0-9a-f]{40}$ ]] || { echo 'SHA inválido'; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
chmod 700 "$TMP"
printf '%s\n' "$KEY" > "$TMP/deploy_key";chmod 600 "$TMP/deploy_key"
printf '%s\n' "$KNOWN" > "$TMP/known_hosts";chmod 600 "$TMP/known_hosts"
SSH=(ssh -i "$TMP/deploy_key" -p "$PORT" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$TMP/known_hosts" -o BatchMode=yes)
SCP=(scp -i "$TMP/deploy_key" -P "$PORT" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$TMP/known_hosts" -o BatchMode=yes)
tar -czf "$TMP/roots-site.tar.gz" -C site .
"${SSH[@]}" "$USER@$HOST" 'bash -s' <<'CHECK'
set -euo pipefail
root='/home/dalypxmu/admroots.dalyfinanzas.com'
test "$(id -un)" = 'dalypxmu'
test -d "$root" && test ! -L "$root" && test -f "$root/.roots-web-deploy-approved"
test "$(stat -c %U "$root")" = 'dalypxmu'
# Additional exclusion of any existing DalyAccounting application roots.
case "$(readlink -f "$root")" in /home/dalypxmu/admroots.dalyfinanzas.com) ;; *) echo 'DocumentRoot equivocado'; exit 1;; esac
mkdir -p /home/dalypxmu/.roots_web_incoming /home/dalypxmu/.roots_web_backups
chmod 700 /home/dalypxmu/.roots_web_incoming /home/dalypxmu/.roots_web_backups
CHECK
"${SCP[@]}" "$TMP/roots-site.tar.gz" "$USER@$HOST:/home/dalypxmu/.roots_web_incoming/$COMMIT.tar.gz"
"${SSH[@]}" "$USER@$HOST" "bash -s -- $COMMIT" <<'INSTALL'
set -euo pipefail
commit="$1"; [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || exit 1
root='/home/dalypxmu/admroots.dalyfinanzas.com'
incoming="/home/dalypxmu/.roots_web_incoming/$commit.tar.gz"
backup_dir='/home/dalypxmu/.roots_web_backups'
test -d "$root" && test ! -L "$root" && test -f "$root/.roots-web-deploy-approved"
test "$(readlink -f "$root")" = "$root"
test -f "$incoming"
release="$(mktemp -d /home/dalypxmu/.roots_web_incoming/release.XXXXXXXX)"
trap 'rm -rf "$release"; rm -f "$incoming"' EXIT
tar -xzf "$incoming" -C "$release" --no-same-owner --no-same-permissions
test -s "$release/index.html" && test -f "$release/robots.txt" && test -d "$release/assets"
backup="$backup_dir/pre_${commit}_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$backup" -C "$root" .
test -s "$backup" || exit 1
# Copy-only: never delete unrelated files, databases, or uploads.
if ! cp -a "$release/." "$root/"; then
  echo 'Error de copia. Se intentará restaurar sobre los archivos anteriores.'
  tar -xzf "$backup" -C "$root" || true
  exit 1
fi
printf '%s\n' "$backup" > /home/dalypxmu/.roots_web_incoming/last_backup.txt
printf 'ROOTS_DEPLOY_OK:%s; BACKUP:%s\n' "$commit" "$backup"
INSTALL

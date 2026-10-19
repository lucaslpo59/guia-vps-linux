#!/usr/bin/env bash
# Backup diário: pastas + banco MySQL num .tar.gz com data, guarda N dias
# e opcionalmente envia uma cópia para outro servidor.
#
# A senha do banco fica em /root/.my.cnf (chmod 600), nunca neste arquivo:
#   [client]
#   user=backup
#   password=...

set -euo pipefail

PASTAS=(/opt/minha-api /var/www/meusite /etc/nginx/sites-available)
BANCOS=(meubanco)
DESTINO=/var/backups/servidor
MANTER_DIAS=14
REMOTO=""          # ex: backup@198.51.100.20:/backups/ (vazio = não envia)

DATA=$(date +%F_%H%M)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$DESTINO"

for banco in "${BANCOS[@]}"; do
  echo "dump do banco $banco"
  mysqldump --single-transaction --routines --triggers "$banco" | gzip > "$TMP/$banco.sql.gz"
done

ARQUIVO="$DESTINO/backup_$DATA.tar.gz"
echo "compactando para $ARQUIVO"
tar -czf "$ARQUIVO" \
  --exclude='node_modules' --exclude='*.log' \
  -C / "${PASTAS[@]#/}" \
  -C "$TMP" .

# Confere se o arquivo não está corrompido
tar -tzf "$ARQUIVO" > /dev/null

find "$DESTINO" -name 'backup_*.tar.gz' -mtime +"$MANTER_DIAS" -delete

if [ -n "$REMOTO" ]; then
  echo "enviando para $REMOTO"
  rsync -a --partial "$ARQUIVO" "$REMOTO"
fi

echo "ok: $(du -h "$ARQUIVO" | cut -f1)"

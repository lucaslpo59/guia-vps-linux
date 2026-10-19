# 5. Backup e migração de servidor

Backup que nunca foi restaurado é só uma esperança. A regra que sigo: pelo menos uma vez, restaurar num lugar separado e conferir se a aplicação sobe.

## O que entra no backup

| O quê | Onde costuma ficar |
|---|---|
| Código e arquivos publicados | `/opt/*`, `/var/www/*` (o código também está no git) |
| Configurações e segredos | `.env` de cada aplicação |
| Uploads de usuários | pasta de uploads da aplicação |
| Banco de dados | dump do MySQL/MariaDB |
| Nginx | `/etc/nginx/sites-available/` |
| Serviços | `/etc/systemd/system/*.service`, `~/.config/systemd/user/` |
| Certificados | `/etc/letsencrypt/` (ou emitir de novo no destino) |
| Agendamentos | `crontab -l` de cada usuário, timers do systemd |

## Banco de dados

```bash
mysqldump --single-transaction --routines --triggers banco | gzip > banco_$(date +%F).sql.gz
```

`--single-transaction` tira uma cópia consistente sem travar as tabelas (InnoDB). Para restaurar:

```bash
gunzip < banco_2026-10-01.sql.gz | mysql banco
```

## Backup diário automático

O script [`exemplos/backup.sh`](../exemplos/backup.sh) junta pastas e banco num `.tar.gz` com data, guarda os últimos 14 dias e pode mandar uma cópia para outro servidor com `rsync`. Agende com o timer do [capítulo 3](03-servicos-systemd.md) ou no cron:

```bash
0 3 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

Backup guardado só no próprio servidor não protege contra perda da VPS. Mantenha pelo menos uma cópia fora dela.

## Checklist para trocar de VPS

Usei este roteiro para mudar uma plataforma inteira (site, API e serviços) de um servidor para outro:

1. **Inventário do antigo**: `systemctl list-units --type=service --state=running`, `ss -tulnp`, `crontab -l`, sites do Nginx. Anotar tudo que roda e em qual porta.
2. **Backup completo** e cópia para fora do servidor antigo.
3. **Preparar o novo** com o [capítulo 1](01-acesso-e-seguranca.md) (usuário, chave, firewall, fail2ban).
4. **Instalar as mesmas versões** (Node, banco). Versão diferente é a causa mais comum de "no antigo funcionava".
5. **Restaurar** arquivos, `.env`, banco e serviços. Subir e testar acessando pelo IP novo, antes de mexer no DNS.
6. **Diminuir o TTL do DNS** um dia antes (300 segundos) para a troca valer rápido.
7. **Trocar o DNS**, emitir os certificados no novo e acompanhar os logs.
8. **Manter o antigo ligado** alguns dias, mas com os serviços parados, para não ficarem dois servidores gravando dados.
9. **Conferir integrações externas**: webhooks de pagamento, IPs liberados em APIs de terceiros, apps que têm o endereço fixo no código.

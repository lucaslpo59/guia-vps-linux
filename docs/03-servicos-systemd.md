# 3. Aplicações como serviço (systemd)

Rodar `node server.js` no terminal funciona até a sessão cair. Como serviço do systemd a aplicação sobe junto com o servidor, reinicia sozinha se travar e tem os logs guardados.

## Usuário próprio para a aplicação

```bash
sudo adduser --system --group --home /opt/minha-api minha-api
sudo chown -R minha-api:minha-api /opt/minha-api
```

Se a aplicação for invadida, o atacante fica preso às permissões desse usuário e não ao root.

## Criar o serviço

Arquivo completo em [`exemplos/minha-api.service`](../exemplos/minha-api.service). Ele vai em `/etc/systemd/system/minha-api.service`:

```ini
[Unit]
Description=API do projeto
After=network-online.target
Wants=network-online.target

[Service]
User=minha-api
WorkingDirectory=/opt/minha-api
EnvironmentFile=/opt/minha-api/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now minha-api
systemctl status minha-api
```

As senhas e chaves ficam no `.env` (com `chmod 600`), fora do código e fora do git.

## Comandos do dia a dia

```bash
sudo systemctl restart minha-api
journalctl -u minha-api -f                 # log ao vivo
journalctl -u minha-api --since "1 hour ago"
journalctl -u minha-api -p err -b          # só erros desde o último boot
systemctl --failed                         # tudo que caiu
systemctl list-timers                      # tarefas agendadas
```

## Serviço sem sudo (systemd de usuário)

Quando a aplicação roda com um usuário comum que não tem sudo, ela pode ter o próprio systemd:

```bash
# como root, uma vez: mantém os serviços do usuário vivos sem ele estar logado
loginctl enable-linger minha-api

# como o usuário
mkdir -p ~/.config/systemd/user
cp minha-api.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now minha-api
journalctl --user -u minha-api -f
```

Nesse caso tire a linha `User=` do arquivo e troque `multi-user.target` por `default.target`.

## Tarefa agendada com timer

Alternativa ao cron com log no journalctl. Exemplo para rodar o backup às 3h:

```ini
# /etc/systemd/system/backup.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh

# /etc/systemd/system/backup.timer
[Timer]
OnCalendar=*-*-* 03:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl enable --now backup.timer
```

`Persistent=true` roda o backup perdido se o servidor estava desligado no horário.

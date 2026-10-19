# Guia de VPS Linux na prática

Anotações de quem mantém servidores Ubuntu em produção para projetos próprios: a API e o site de uma plataforma de delivery e um servidor de jogo multiplayer com banco MySQL. É o passo a passo que eu sigo hoje, com os erros que me ensinaram cada parte.

Os comandos foram usados em Ubuntu 22.04/24.04. Endereços, domínios e usuários estão trocados por exemplos.

## Conteúdo

1. [Primeiro acesso e segurança](docs/01-acesso-e-seguranca.md): usuário sem root, chave SSH, firewall, fail2ban, atualizações automáticas
2. [Nginx e HTTPS](docs/02-nginx-e-https.md): site estático, proxy reverso para uma API e certificado gratuito
3. [Aplicações como serviço](docs/03-servicos-systemd.md): systemd, reinício automático, logs com journalctl
4. [Deploy com git push](docs/04-deploy-com-git.md): repositório no servidor que publica sozinho a cada push
5. [Backup e migração de servidor](docs/05-backup-e-migracao.md): o que copiar, banco de dados e checklist para trocar de VPS
6. [Lições aprendidas](docs/licoes-aprendidas.md): problemas reais e como resolvi

## Arquivos de exemplo

| Arquivo | Para quê |
|---|---|
| [`exemplos/jail.local`](exemplos/jail.local) | Configuração do fail2ban para SSH |
| [`exemplos/nginx-site.conf`](exemplos/nginx-site.conf) | Site + proxy reverso para API em Node.js |
| [`exemplos/minha-api.service`](exemplos/minha-api.service) | Unidade systemd com reinício automático |
| [`exemplos/post-receive`](exemplos/post-receive) | Hook do git que publica a cada push |
| [`exemplos/backup.sh`](exemplos/backup.sh) | Backup diário de arquivos e MySQL com rotação |

## Checklist rápido de um servidor novo

- [ ] Atualizar o sistema (`apt update && apt upgrade`)
- [ ] Criar usuário com sudo e entrar com chave SSH
- [ ] Desligar login por senha e login direto como root
- [ ] Liberar no firewall só as portas usadas
- [ ] Instalar fail2ban (com o seu IP no `ignoreip`)
- [ ] Ativar atualizações de segurança automáticas
- [ ] Cada aplicação com usuário próprio e serviço no systemd
- [ ] HTTPS em todos os domínios
- [ ] Backup diário testado (restaurar pelo menos uma vez)

# 1. Primeiro acesso e segurança

Um servidor novo na internet começa a receber tentativas de login por SSH em minutos. Esta é a primeira coisa a fazer, antes de instalar qualquer aplicação.

## Atualizar e criar um usuário

```bash
apt update && apt upgrade -y
adduser lucas
usermod -aG sudo lucas
```

Daqui em diante o trabalho é feito com esse usuário e `sudo`, nunca logado como root.

## Entrar com chave em vez de senha

No seu computador (Windows 10/11 já tem o OpenSSH):

```powershell
ssh-keygen -t ed25519 -C "notebook-lucas"
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh lucas@203.0.113.10 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Teste se entra sem pedir senha **em outro terminal, sem fechar o atual**. Se algo der errado no próximo passo, a sessão aberta é o que salva.

## Desligar senha e root no SSH

Em `/etc/ssh/sshd_config` (ou num arquivo em `/etc/ssh/sshd_config.d/`):

```
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
```

```bash
sudo sshd -t && sudo systemctl reload ssh
```

O `sshd -t` valida o arquivo antes. Recarregar com erro de sintaxe pode deixar você trancado para fora.

## Firewall (ufw)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80,443/tcp
sudo ufw enable
sudo ufw status verbose
```

Liberar `OpenSSH` **antes** do `enable`. Porta de banco de dados (3306, 5432) não fica aberta para a internet. Se precisar acessar de fora, use um túnel SSH:

```bash
ssh -L 3306:127.0.0.1:3306 lucas@203.0.113.10
```

## fail2ban

Bloqueia por um tempo o IP que erra o login várias vezes.

```bash
sudo apt install fail2ban -y
sudo cp exemplos/jail.local /etc/fail2ban/jail.local   # veja o arquivo de exemplo
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

Coloque o IP de onde você administra no `ignoreip`. Eu aprendi isso sendo bloqueado pelo meu próprio servidor (está nas [lições aprendidas](licoes-aprendidas.md)).

Para desbloquear um IP:

```bash
sudo fail2ban-client set sshd unbanip 198.51.100.7
```

## Atualizações de segurança automáticas

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

Isso instala sozinho só as atualizações de segurança. Quando existir `/var/run/reboot-required`, o servidor precisa ser reiniciado (escolha um horário de pouco uso).

## Conferir

```bash
sudo ss -tulnp              # o que está escutando e em qual porta
sudo journalctl -u ssh -n 50
last -n 20                  # últimos logins com sucesso
```

# Lições aprendidas

Problemas que aconteceram de verdade nos meus servidores, o que causou e o que mudei.

## Fui bloqueado pelo meu próprio fail2ban

**O que aconteceu:** uma automação abria uma conexão SSH nova para cada comando. Foram dezenas de conexões em poucos segundos, o fail2ban entendeu como ataque e bloqueou o meu IP.

**Correção:** coloquei meu IP no `ignoreip` do `jail.local` e passei a agrupar os comandos numa conexão só:

```bash
ssh servidor 'comando1 && comando2 && comando3'
```

Para muitas conexões seguidas, o `ControlMaster` do SSH reaproveita a mesma conexão:

```
# ~/.ssh/config
Host servidor
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

## Arquivo apagado no repositório continuava no servidor

**O que aconteceu:** o hook de deploy usava `git checkout -f`. Ele atualiza e cria arquivos, mas não apaga os que saíram do repositório. Um script removido continuava sendo carregado em produção.

**Correção:** `git clean -fd` depois do checkout. Sem `-x`, para não apagar `.env` e uploads que estão no `.gitignore`.

## O deploy "voltava sozinho" depois de reiniciar

**O que aconteceu:** eu publicava o site novo, estava tudo certo, e depois de um reboot a versão antiga reaparecia. Existia um serviço antigo esquecido que, ao subir, copiava os arquivos de outra pasta por cima.

**Correção:** desativei o serviço velho e deixei um único caminho de deploy. Hoje, quando algo muda sem ninguém mexer, a primeira coisa que olho é:

```bash
systemctl list-units --type=service --state=running
systemctl list-timers
crontab -l; sudo crontab -l
```

## Restart de um serviço derrubou outros

**O que aconteceu:** reiniciei um componente do servidor de jogo e os que dependiam dele pararam junto, sem subir de volta.

**Correção:** antes de reiniciar, ver quem depende do serviço. No systemd, `Requires=`/`PartOf=` resolvem a ordem. Em sistemas com gerenciador próprio, reiniciar os dependentes explicitamente depois.

```bash
systemctl list-dependencies --reverse minha-api
```

## Linha duplicada no banco a cada reinício

**O que aconteceu:** um registro criado na inicialização com `INSERT IGNORE` duplicava toda vez que o serviço reiniciava. A chave única incluía uma coluna que estava `NULL`, e no MySQL dois `NULL` nunca são considerados iguais, então a chave única não barrava.

**Correção:** coluna da chave única com `NOT NULL` e valor padrão, e limpeza das duplicadas:

```sql
ALTER TABLE contas MODIFY dono VARCHAR(60) NOT NULL DEFAULT '';
```

## Minerador escondido num computador

**O que aconteceu:** um PC com Windows travava em jogos e programas pesados sem motivo aparente. Era um trojan que se injetava num processo legítimo do sistema (`nslookup.exe`) para minerar criptomoeda e usar a placa de vídeo.

**Correção:** identifiquei o processo pelo consumo de GPU e pelo caminho de execução estranho, encerrei, removi a persistência (tarefa agendada e chave de inicialização) e fiz varredura completa. Lição para servidores também: processo com nome conhecido não é garantia de nada. Conferir o caminho do executável e quem o iniciou.

```bash
# Linux: caminho real e processo pai
ls -l /proc/<PID>/exe
ps -o ppid=,cmd= -p <PID>
```

# 4. Deploy com git push

Em vez de copiar arquivos por FTP, o servidor tem um repositório git. Um `git push` publica a versão nova e reinicia a aplicação. Fica registrado o que foi publicado e quando, e voltar uma versão é um comando.

```
PC  ──git push vps main──>  /srv/git/projeto.git  ──hook──>  /opt/projeto (arquivos publicados)
                                                         └──> systemctl restart
```

## No servidor

```bash
sudo mkdir -p /srv/git && sudo chown lucas: /srv/git
git init --bare /srv/git/projeto.git
cp exemplos/post-receive /srv/git/projeto.git/hooks/post-receive
chmod +x /srv/git/projeto.git/hooks/post-receive
```

O hook completo está em [`exemplos/post-receive`](../exemplos/post-receive). O coração dele:

```bash
git --work-tree="$DESTINO" --git-dir="$REPO" checkout -f main
git --work-tree="$DESTINO" --git-dir="$REPO" clean -fd
```

O `clean -fd` é o que apaga do servidor os arquivos que você apagou no repositório. Sem ele, arquivo removido continua lá para sempre (ver [lições aprendidas](licoes-aprendidas.md)).

Não use `clean -fdx`. O `-x` apaga também o que está no `.gitignore`, e é lá que ficam o `.env`, os uploads e os logs.

O hook reinicia o serviço com `sudo`. Para não pedir senha no meio do push, libere só esse comando com `sudo visudo -f /etc/sudoers.d/deploy`:

```
lucas ALL=(root) NOPASSWD: /usr/bin/systemctl restart minha-api
```

Liberar só o comando exato, e não `ALL`, mantém o resto do sudo protegido por senha.

## No seu PC

```bash
git remote add vps lucas@203.0.113.10:/srv/git/projeto.git
git push vps main
```

A saída do hook aparece no seu terminal com o prefixo `remote:`, então você vê na hora se o restart deu certo.

## Duas pessoas publicando

Se outra pessoa também faz push no mesmo servidor, o seu pode ser recusado:

```
! [rejected]        main -> main (fetch first)
```

Isso quer dizer que tem commit dela que você ainda não tem. O certo é:

```bash
git pull --rebase vps main
git push vps main
```

Nunca `git push --force` num servidor compartilhado. Ele apaga o trabalho do outro.

## Voltar uma versão

```bash
git revert HEAD        # cria um commit que desfaz o último
git push vps main
```

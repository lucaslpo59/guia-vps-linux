# 2. Nginx e HTTPS

O Nginx fica na frente de tudo: entrega os arquivos do site e repassa as chamadas da API para a aplicação, que roda só em `127.0.0.1` e nunca fica exposta direto.

```
internet ──443──> nginx ──> /var/www/meusite      (site estático)
                     └────> 127.0.0.1:3000        (API em Node.js)
```

## Instalar

```bash
sudo apt install nginx -y
sudo systemctl enable --now nginx
```

## Configurar o site

O arquivo completo está em [`exemplos/nginx-site.conf`](../exemplos/nginx-site.conf). O essencial:

```nginx
server {
    server_name exemplo.com.br www.exemplo.com.br;
    root /var/www/meusite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/meusite /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Sempre `nginx -t` antes do reload. Com erro no arquivo o reload falha e os sites continuam com a configuração antiga, mas um restart derrubaria todos.

## HTTPS gratuito (Let's Encrypt)

O domínio precisa já estar apontando para o IP do servidor.

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d exemplo.com.br -d www.exemplo.com.br
sudo certbot renew --dry-run
```

O certbot altera o arquivo do Nginx, cria o redirecionamento de HTTP para HTTPS e agenda a renovação sozinho.

## Eventos em tempo real (SSE) e WebSocket

Se a API manda atualizações ao vivo (pedido mudou de status, por exemplo), o Nginx precisa parar de segurar a resposta em buffer, senão o navegador só recebe tudo de uma vez no final:

```nginx
location /api/eventos {
    proxy_pass http://127.0.0.1:3000/eventos;
    proxy_buffering off;
    proxy_read_timeout 1h;
}
```

Para WebSocket:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## Onde olhar quando dá erro

| Sintoma | Causa comum | Onde ver |
|---|---|---|
| 502 Bad Gateway | aplicação parada ou em outra porta | `systemctl status minha-api` |
| 504 Gateway Timeout | aplicação travada ou consulta lenta | log da aplicação |
| 403 Forbidden | permissão da pasta do site | `ls -la /var/www/meusite` |
| site antigo aparece | cache do navegador ou do CDN | Ctrl+F5, `curl -I` |

```bash
sudo tail -f /var/log/nginx/error.log
```

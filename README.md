
# [caddy](https://hub.docker.com/r/swarmstack/caddy/)

A tiny Caddy image compressed with [UPX](https://github.com/upx/upx).

# Usage

Serve files in `$PWD`:
```
docker run -it --rm -p 2015:2015 -v $PWD:/srv swarmstack/caddy
```
---
Overwrite `Caddyfile`:
```
docker run -it --rm -p 2015:2015 -v $PWD:/srv -v $PWD/Caddyfile:/etc/Caddyfile swarmstack/caddy
```
---
Persist `/etc/.caddy` to avoid hitting Let's Encrypt's rate limit (ENV CADDYPATH=/etc/caddycerts):
```
docker run -it --rm -p 2015:2015 -v $PWD:/srv -v $PWD/Caddyfile:/etc/Caddyfile -v $HOME/.caddy:/etc/caddycerts swarmstack/caddy
```

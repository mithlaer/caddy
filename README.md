
# [caddy](https://github.com/mholt/caddy/)

A tiny Caddy image compressed with [UPX](https://github.com/upx/upx).

# Usage

Serve files in `$PWD`:
```
docker run -it --rm -p 2015:2015 -v $PWD:/www swarmstack/caddy
```
---
Overwrite `Caddyfile`:
```
docker run -it --rm -p 2015:2015 -v $PWD:/www -v $PWD/Caddyfile:/etc/Caddyfile swarmstack/caddy
```
---
Persist `/etc/caddycerts` to avoid hitting Let's Encrypt's rate limit (ENV CADDYPATH=/etc/caddycerts):
```
docker run -it --rm -p 2015:2015 -v $PWD:/www -v $PWD/Caddyfile:/etc/Caddyfile -v $PWD/caddycerts:/etc/caddycerts swarmstack/caddy
```

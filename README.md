
# [caddy](https://github.com/mholt/caddy/)

A Caddy image with and without telemetry (no-stats)

[https://hub.docker.com/r/swarmstack/caddy/](https://hub.docker.com/r/swarmstack/caddy/)

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

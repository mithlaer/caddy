#
# Build stage by @abiosoft https://github.com/abiosoft/caddy-docker
#
FROM golang:1.11-alpine as build

ARG version="v0.11.0"
ARG plugins="prometheus"

RUN apk add --no-cache git

# caddy
RUN git clone https://github.com/mholt/caddy -b "${version}" /go/src/github.com/mholt/caddy \
    && cd /go/src/github.com/mholt/caddy \
    && git checkout -b "${version}"

# plugin helper
RUN go get -v github.com/abiosoft/caddyplug/caddyplug

# plugins
RUN for plugin in $(echo $plugins | tr "," " "); do \
    go get -v $(caddyplug package $plugin); \
    printf "package caddyhttp\nimport _ \"$(caddyplug package $plugin)\"" > \
        /go/src/github.com/mholt/caddy/caddyhttp/$plugin.go ; \
    done

# builder dependency
RUN git clone https://github.com/caddyserver/builds /go/src/github.com/caddyserver/builds

# build with telemetry enabled
RUN cd /go/src/github.com/mholt/caddy/caddy \
    && git checkout -f \
    && go run build.go \
    && mv caddy /go/bin


#
# Compress Caddy with upx
#
FROM debian:stable as compress

# curl, tar
RUN apt-get update && apt install -y --no-install-recommends \
    tar \
    xz-utils \
    curl \
    ca-certificates

# get official upx binary
RUN curl --silent --show-error --fail --location -o - \
    "https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz" \
    | tar --no-same-owner -C /usr/bin/ -xJ \
    --strip-components 1 upx-3.95-amd64_linux/upx

# copy and compress
COPY --from=build /go/bin/caddy /usr/bin/caddy
RUN /usr/bin/upx --ultra-brute /usr/bin/caddy

# test
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

#
# Final image
#
FROM scratch

# labels
LABEL org.label-schema.vcs-url="https://github.com/swarmstack/caddy"
LABEL org.label-schema.version=${version}
LABEL org.label-schema.schema-version="1.0"

# copy caddy binary and ca certs
COPY --from=compress /usr/bin/caddy /bin/caddy
COPY --from=compress /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# copy default caddyfile
COPY Caddyfile /etc/Caddyfile

# set default caddypath for storing certs
ENV CADDYPATH=/etc/caddycerts

# serve from /www
WORKDIR /www
COPY index.html /www/index.html

ENTRYPOINT ["/bin/caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=true"]

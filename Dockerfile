#
# Build stage by @abiosoft https://github.com/abiosoft/caddy-docker
#
FROM golang:1.14-alpine as build

ARG BUILD_DATE
ARG VCS_REF
ARG DEBIAN_FRONTEND=noninteractive

ARG caddy_version="master"
ARG plugins="cache,expires,git,jwt,prometheus,realip,reauth"

RUN apk add --no-cache --no-progress git ca-certificates

# caddy
#RUN git clone https://github.com/caddyserver/caddy -b "${caddy_version}" /go/src/github.com/caddyserver/caddy \
#    && cd /go/src/github.com/caddyserver/caddy \
#    && git checkout -b "${caddy_version}"

# if running from master
RUN git clone https://github.com/caddyserver/caddy -b "${caddy_version}" /go/src/github.com/caddyserver/caddy

# plugin helper
RUN go get -v github.com/abiosoft/caddyplug/caddyplug

# plugins
RUN for plugin in $(echo $plugins | tr "," " "); do \
    go get -v $(caddyplug package $plugin); \
    printf "package caddyhttp\nimport _ \"$(caddyplug package $plugin)\"" > \
        /go/src/github.com/caddyserver/caddy/caddyhttp/$plugin.go ; \
    done

# Deal with https://github.com/miekg/caddy-prometheus/issues/43
COPY patches/handler.go /go/src/github.com/miekg/caddy-prometheus/handler.go

# build with telemetry enabled
RUN cd /go/src/github.com/caddyserver/caddy/caddy \
    && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/bin/caddy

# test
RUN /go/bin/caddy -version
RUN /go/bin/caddy -plugins

#
# Final image
#
FROM scratch

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/swarmstack/caddy.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1"

MAINTAINER Mike Holloway <mikeholloway+swarmstack@gmail.com>

# copy caddy binary and ca certs
COPY --from=build /go/bin/caddy /bin/caddy
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# copy default caddyfile
COPY Caddyfile /etc/Caddyfile

# set default path for certs
VOLUME ["/etc/caddycerts"]
ENV CADDYPATH=/etc/caddycerts

# serve from /www
VOLUME ["/www"]
WORKDIR /www
COPY index.html /www/index.html

CMD ["/bin/caddy", "-conf", "/etc/Caddyfile", "-log", "stdout", "-agree", "-root", "/www"]

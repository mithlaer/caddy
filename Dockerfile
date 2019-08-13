#
# Build stage by @abiosoft https://github.com/abiosoft/caddy-docker
#
FROM golang:1.12-alpine as build

ARG BUILD_DATE
ARG VCS_REF
ARG DEBIAN_FRONTEND=noninteractive

ARG caddy_version="v1.0.1"
ARG plugins="cache,expires,git,jwt,prometheus,realip,reauth"

RUN apk add --no-cache --no-progress git ca-certificates

# caddy
RUN git clone https://github.com/caddyserver/caddy -b "${caddy_version}" /go/src/github.com/caddyserver/caddy \
    && cd /go/src/github.com/caddyserver/caddy \
    && git checkout -b "${caddy_version}"


# plugin helper
RUN go get -v github.com/abiosoft/caddyplug/caddyplug
RUN sed -i 's/mholt\/caddy"/caddyserver\/caddy"/g' /go/bin/caddyplug

# plugins
RUN for plugin in $(echo $plugins | tr "," " "); do \
    go get -v $(caddyplug package $plugin); \
    printf "package caddyhttp\nimport _ \"$(caddyplug package $plugin)\"" > \
        /go/src/github.com/caddyserver/caddy/caddyhttp/$plugin.go ; \
    done

# https://github.com/coredns/coredns/issues/2959
RUN find /go/src/github.com/ -name '*.go' | while read -r f; do \
      sed -i.bak 's/\/mholt\/caddy/\/caddyserver\/caddy/g' $f && rm $f.bak ; \
    done

# builder dependency
RUN git clone https://github.com/dustin/go-humanize /go/src/github.com/dustin/go-humanize
RUN git clone https://github.com/gorilla/websocket /go/src/github.com/gorilla/websocket
RUN git clone https://github.com/jimstudt/http-authentication /go/src/github.com/jimstudt/http-authentication
RUN git clone https://github.com/naoina/toml /go/src/github.com/naoina/toml
RUN git clone https://github.com/naoina/go-stringutil /go/src/github.com/naoina/go-stringutil
RUN git clone https://github.com/VividCortex/ewma /go/src/github.com/VividCortex/ewma
RUN git clone https://github.com/marten-seemann/qpack /go/src/github.com/marten-seemann/qpack
RUN git clone https://github.com/cheekybits/genny /go/src/github.com/cheekybits/genny
RUN git clone --single-branch --branch v0.2.3 https://github.com/marten-seemann/qtls /go/src/github.com/marten-seemann/qtls
RUN git clone https://github.com/bifurcation/mint /go/src/github.com/bifurcation/mint
RUN git clone https://github.com/lucas-clemente/aes12 /go/src/github.com/lucas-clemente/aes12
RUN git clone https://github.com/lucas-clemente/quic-go-certificates /go/src/github.com/lucas-clemente/quic-go-certificates
RUN rm -rf /go/src/github.com/lucas-clemente/quic-go && git clone --single-branch --branch v0.11.2 https://github.com/lucas-clemente/quic-go /go/src/github.com/lucas-clemente/quic-go

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

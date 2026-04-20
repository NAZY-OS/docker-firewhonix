# Base Image
FROM alpine:latest


# Update and install required packages
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    nano \
    git \
    curl \
    coreutils \
    wget \
    go \
    tor \
    sudo \
    dnsmasq \
    dnscrypt-proxy

# Optionally, upgrade pip for Python 3 to the latest version
#RUN python3 -m pip install --upgrade pip

# Clone and build go-dispatch-proxy
RUN git clone https://github.com/extremecoders-re/go-dispatch-proxy /tmp/go-dispatch-proxy && \
    cd /tmp/go-dispatch-proxy && \
    go build && \
    chmod +x go-dispatch-proxy && \
    mv go-dispatch-proxy /usr/bin/go-dispatch-proxy && \
    rm -rf /tmp/go-dispatch-proxy

# Copy start scripts
COPY start.sh /sbin/start.sh
COPY start_dispatcher.sh /sbin/start_dispatcher.sh

# Copy dnscrypt-proxy settings
RUN mkdir /etc/dnscrypt-proxy/
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml

# Expose ports
EXPOSE 4711 9051-9062 9080

# Start Tor and the proxy
CMD ["/sbin/start.sh"]

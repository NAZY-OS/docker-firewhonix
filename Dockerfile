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
    openssl \
    libcap \
    dnsmasq \
    dnscrypt-proxy \
    dnscrypt-proxy-openrc \
    libunwind \
    libevent \
    stubby

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

RUN chmod +x /sbin/start.sh; chmod +x /sbin/start_dispatcher.sh

# Copy dnscrypt-proxy settings
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml

# Generate dnscrypt config
#COPY generate-dnscrypt-config.sh /sbin/generate-dnscrypt-config.sh 
#RUN chmod +x /sbin/generate-dnscrypt-config.sh
#RUN bash /sbin/generate-dnscrypt-config.sh

#RUN cp /tmp/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml

# Fix file permissions and groups
# Set the owner to root for all files
RUN /bin/sh -c "chown root:root /sbin/start_dispatcher.sh \
                      /etc/dnscrypt-proxy/dnscrypt-proxy.toml \
                      /usr/bin/go-dispatch-proxy \
                      /sbin/start.sh"

# Set permissions to 755 for all files
RUN /bin/sh -c "chmod 755 /sbin/start_dispatcher.sh \
                /etc/dnscrypt-proxy/dnscrypt-proxy.toml \
                /usr/bin/go-dispatch-proxy \
                /sbin/start.sh"


# Expose ports
EXPOSE 4711 9051-9062 9080

# Start Tor and the proxy
CMD ["/sbin/start.sh"]

# Base Image
FROM fedora:43

# Set the working directory
WORKDIR /home/toranon

VOLUME [ "/home/toranon" ]

# Remove redundant repositories
RUN rm /etc/yum.repos.d/fedora-cisco-openh264.repo
RUN rm /etc/yum.repos.d/fedora-updates-testing.repo

# Uncomment to clean the yum cache
#RUN dnf clean expire-cache

# Install microdnf with fastest mirror option
RUN time dnf -y install microdnf --setopt=fastestmirror=True
    
# Update and install packages
RUN time microdnf -y update && \
    microdnf install -y \
    python3 \
    python3-pip \
    which \
    nano \
    systemd \
    dbus \
    git \
    time \
    curl \
    lsb \
    fakeroot \
    wget \
    procps \
    libcap \
    unzip \
    go \
    tor \
    sudo \
    torsocks

# Optionally, you may want to update pip for Python 3 to the latest version
RUN time pip3 install --upgrade pip

# Download and install dnscrypt-proxy
RUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.1.5/dnscrypt-proxy-linux_x86_64-2.1.5.tar.gz -O /tmp/dnscrypt-proxy.tar.gz && \
    tar xvf /tmp/*.tar.gz -C /tmp && cp /tmp/linux-x86_64/dnscrypt-proxy /usr/bin/dnscrypt-proxy && rm -rf /tmp/* && mkdir -p \
    /etc/dnscrypt-proxy /var/cache/dnscrypt-proxy /lib/systemd/system/apt-cacher-ng.service.d

# Download the latest release executable for go-dispatch-proxy and build it
RUN git clone https://github.com/extremecoders-re/go-dispatch-proxy && cd go-dispatch-proxy ; go build && chmod +x go-dispatch-proxy && mv go-dispatch-proxy /bin/go-dispatch-proxy

# Create user toranon with UID 999, uncomment to enable
#RUN useradd -u 999 -m toranon && \
#    echo "toranon:password" | chpasswd && \
#    adduser toranon sudo

# Set the user to toranon, uncomment to enable
#USER toranon

# Copy start scripts
COPY start.sh /sbin/start.sh
COPY start_dispatcher.sh /sbin/start_dispatcher.sh

# Uncomment to set nameserver
#RUN echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Expose ports
EXPOSE 4711 9051-9062 9080

# Start Tor and the proxy
CMD ["/sbin/start.sh"]

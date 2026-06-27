FROM nvidia/cuda:12.6.3-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    VNC_PASSWORD=admin123 \
    CODE_PASSWORD=admin123 \
    DISPLAY=:1 \
    HOME=/root

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
      xfce4 xfce4-goodies \
      tigervnc-standalone-server tigervnc-common tigervnc-tools \
      nginx supervisor \
      python3-pip python3 \
      curl ca-certificates unzip wget \
      dbus-x11 x11-xserver-utils xfonts-base \
      firefox proot \
      mesa-utils glmark2 libxv1 libxtst6 libegl1 libgl1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN VGL_VER=3.1.2 && \
    curl -fsSL "https://github.com/VirtualGL/virtualgl/releases/download/${VGL_VER}/virtualgl_${VGL_VER}_amd64.deb" \
      -o /tmp/virtualgl.deb && \
    apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends /tmp/virtualgl.deb && \
    rm /tmp/virtualgl.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN mkdir -p /opt/novnc && \
    curl -fsSL https://github.com/novnc/noVNC/archive/refs/tags/v1.7.0.tar.gz | \
    tar -xz -C /opt/ && \
    cp -r /opt/noVNC-1.7.0/* /opt/novnc/ && \
    rm -rf /opt/noVNC-1.7.0 && \
    ls -la /opt/novnc/ | head -10

RUN pip3 install --break-system-packages websockify

RUN mkdir -p /root/.vnc /root/.config/code-server /root/workspace && \
    echo "admin123" | tigervncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    printf 'bind-addr: 127.0.0.1:8081\nauth: password\npassword: admin123\ncert: false\n' > /root/.config/code-server/config.yaml

COPY xstartup /root/.vnc/xstartup
RUN chmod +x /root/.vnc/xstartup

COPY nginx-default /etc/nginx/sites-available/default
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

COPY supervisord.conf /etc/supervisor/conf.d/devstation.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

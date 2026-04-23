FROM debian:stable-slim

ARG NGROK_TOKEN
ARG REGION=ap

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server wget unzip vim curl python3 \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/ngrok \
    && rm /tmp/ngrok.zip

# Setup SSH + startup script
RUN mkdir -p /run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd \
    && printf '#!/bin/bash\n\
ngrok config add-authtoken %s\n\
ngrok tcp --region %s 22 &\n\
sleep 5\n\
curl -s http://localhost:4040/api/tunnels | python3 -c '\''import sys,json; d=json.load(sys.stdin); print(\"ssh info:\\n\", \"ssh\", \"root@\"+d[\"tunnels\"][0][\"public_url\"][6:].replace(\":\",\" -p \"), \"\\nROOT Password:craxid\")'\'' || echo \"NGROK error\"\n\
/usr/sbin/sshd -D\n' "$NGROK_TOKEN" "$REGION" > /openssh.sh \
    && chmod +x /openssh.sh

EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

CMD ["/openssh.sh"]

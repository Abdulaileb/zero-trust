FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    net-tools \
    iproute2 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Argon2 library
RUN pip install argon2-cffi

RUN mkdir -p /etc/config /www_provision/cgi-bin /www_trusted

WORKDIR /src

COPY ./src/boot-enforcer/rc.local.sh /etc/config
COPY ./src/www_provision/cgi-bin/ /www_provision/cgi-bin
COPY ./src/www /src/www_trusted

RUN chmod +x /www_provision/cgi-bin/setup.sh
RUN chmod +x /etc/config

EXPOSE 80 443 8080 99

# Keep container running
# CMD ["tail", "-f", "/dev/null"]

# Use a lightweight Python base
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    net-tools \
    iproute2 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Argon2 library
RUN pip install argon2-cffi

# Setup the Zero-Trust filesystem
RUN mkdir -p /etc/config /www_provision /www_trusted /app
WORKDIR /app

# Copy scripts and web files
COPY ./app/setup.py /app/setup.py
COPY ./app/boot_enforcer.sh /app/boot_enforcer.sh
COPY ./src/www_provision/ /www_provision/
COPY ./src/www/ /www_trusted/

# Set permissions
RUN chmod +x /app/boot_enforcer.sh

# Expose ports for simulation
EXPOSE 80 8080 99

# Start the environment
ENTRYPOINT ["/bin/sh", "/app/boot_enforcer.sh"]

CMD ["--debug"]

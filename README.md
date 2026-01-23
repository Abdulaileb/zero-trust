# Zero-Trust Router Simulation (Digital Twin)

This project provides a portable Docker-based **Digital Twin** of a secure Zero-Trust router environment. It mimics the "Fail-Closed" security logic and cryptographic provisioning flow used in high-security GCP/Cloud deployments.

## Cloud-to-Docker Transition

While the cloud environment uses heavy VPCs and multiple VM interfaces, this Docker implementation focuses on the **Security Logic Engine**:

- **Fail-Closed State**: On startup, the management interface (VLAN 99) is isolated and returns a `403 Forbidden` error.
- **Argon2id Provisioning**: The system requires an administrator to set up credentials via the "Insecure" LAN (Port 8080).
- **State Transition**: Only after a successful Argon2id hash is generated (simulating high CPU load protection) does the "Gate" open, enabling the Secure Management Plane (Port 8099).

## Getting Started (One-Click Setup)

Ensure you have Docker and Docker Compose installed.

1. **Start the Simulation**:
    ```bash
    docker compose up --build
    ```

2. **Access the Provisioning Portal**:
    Open [http://localhost:8080](http://localhost:8080) in your browser.
    - Status: **UNTRUSTED**
    - Goal: Enter credentials to initialize the Zero-Trust profile.

3. **Complete the Setup**:
    Enter a username and a strong password. Click **"Save & Continue"**.

4. **Verify the Cryptographic Proof**:
    Check your terminal logs. You will see the Argon2id hashing process starting, simulating the memory-hard protection against GPU attackers.

5. **Access the Secure Management Plane**:
    Once setup is complete, you will be redirected (or can manually go) to [http://localhost:8099](http://localhost:8099).
    - Status: **TRUSTED**
    - Management Console is now active.

## Project Structure

- `Dockerfile`: Builds the "Router-in-a-Box" environment with Python, Nginx, and required libraries.
- `docker-compose.yml`: Simulates the network bridges and port isolation.
- `app/setup.py`: The Python-based logic engine handling Argon2id and state changes.
- `app/boot_enforcer.sh`: Simulates the `rc.local` boot process to enforce security state.
- `nginx/nginx.conf`: The gatekeeper routing traffic based on the provisioning state.

## Purpose for Partners
This environment proves **"Cooperative Readiness"**. It allows partners to test the security logic in a modular, containerized testbed without needing access to the full GCP production environment.
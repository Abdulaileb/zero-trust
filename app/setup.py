import http.server
import socketserver
import urllib.parse
import json
import os
import time
from argon2 import PasswordHasher

PORT = 5000
HASHER = PasswordHasher(time_cost=2, memory_cost=16384, parallelism=2)
CONFIG_PATH = "/etc/config/zero_trust_complete"
CREDENTIALS_PATH = "/etc/config/zero_trust_credentials"
WAN_STATUS_PATH = "/tmp/wan_status"

class SetupHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/cgi-bin/setup':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            params = urllib.parse.parse_qs(post_data)

            username = params.get('username', [None])[0]
            password = params.get('password', [None])[0]

            if not username or not password:
                self.send_error(400, "Missing username or password")
                return

            print(f"[*] Processing setup for user: {username}")
            print("[*] Starting Argon2id hashing (High CPU load simulated)...")
            
            start_time = time.time()
            password_hash = HASHER.hash(password)
            end_time = time.time()

            print(f"[+] Hashing complete in {end_time - start_time:.2f} seconds.")
            print(f"[+] Hash: {password_hash}")

            # Persist credentials
            os.makedirs(os.path.dirname(CREDENTIALS_PATH), exist_ok=True)
            with open(CREDENTIALS_PATH, "w") as f:
                f.write(f"{username}:{password_hash}\n")

            # Create the "State Change" flag
            with open(CONFIG_PATH, "w") as f:
                f.write("PROVISIONED")

            print("[+] Zero-Trust Gate: OPEN. VLAN 99 Active.")

            # Respond with success page (simplified version of the user's shell script success page)
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            success_html = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>Setup Complete</title>
                <style>
                    body {{ font-family: sans-serif; background: #6366f1; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
                    .card {{ background: white; color: #111827; padding: 2rem; border-radius: 1rem; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 400px; text-align: center; }}
                    h1 {{ color: #059669; }}
                    .btn {{ display: inline-block; margin-top: 1rem; padding: 0.5rem 1rem; background: #6366f1; color: white; text-decoration: none; border-radius: 0.5rem; }}
                </style>
            </head>
            <body>
                <div class="card">
                    <h1>✓ Setup Complete</h1>
                    <p>User <strong>{username}</strong> created.</p>
                    <p>Management access moved to <strong>VLAN 99</strong>.</p>
                    <p>Redirecting to Management Console...</p>
                    <a href="http://localhost:8099" class="btn">Go to Management Dashboard</a>
                    <script>
                        setTimeout(() => {{ window.location.href = "http://localhost:8099"; }}, 5000);
                    </script>
                </div>
            </body>
            </html>
            """
            self.wfile.write(success_html.encode('utf-8'))
        elif self.path == '/cgi-bin/activate_wan':
            with open(WAN_STATUS_PATH, "w") as f:
                f.write("UP")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        elif self.path == '/cgi-bin/deactivate_wan':
            with open(WAN_STATUS_PATH, "w") as f:
                f.write("DOWN")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        elif self.path == '/cgi-bin/custom_reset':
            if os.path.exists(CONFIG_PATH):
                os.remove(CONFIG_PATH)
            if os.path.exists(CREDENTIALS_PATH):
                os.remove(CREDENTIALS_PATH)
            if os.path.exists(WAN_STATUS_PATH):
                os.remove(WAN_STATUS_PATH)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_error(404)

    def do_GET(self):
        if self.path == '/cgi-bin/wan_status':
            status = "DOWN"
            if os.path.exists(WAN_STATUS_PATH):
                with open(WAN_STATUS_PATH, "r") as f:
                    status = f.read().strip()
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(status.encode('utf-8'))
        else:
            self.send_error(404)

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), SetupHandler) as httpd:
        print(f"[*] Setup Logic Engine running on port {PORT}")
        httpd.serve_forever()

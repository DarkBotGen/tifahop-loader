"""Supervise the private relay and Cloudflare tunnel; no pip dependencies."""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import threading
import time
import urllib.request

ROOT = Path(__file__).resolve().parent
URL_FILE = ROOT / 'YOUR-RELAY-URL.txt'
CREATE_NO_WINDOW = 0x08000000 if os.name == 'nt' else 0


def main(background=False):
    import sys
    secret_path = ROOT / 'secret.txt'
    if not secret_path.exists():
        secret_path.write_text(secrets.token_hex(24), encoding='utf-8')
    secret = secret_path.read_text(encoding='utf-8-sig').strip()
    config = json.loads((ROOT / 'settings.json').read_text(encoding='utf-8-sig'))
    port = int(config.get('Port', 8787))
    origin = f'http://127.0.0.1:{port}'
    health = origin + '/' + secret + '/health'
    # A second launch displays the existing URL without starting duplicate servers.
    try:
        with urllib.request.urlopen(health, timeout=2) as response:
            if json.load(response).get('service') == 'TifaHop relay':
                print('Relay already running. See ' + str(URL_FILE), flush=True)
                if not background and URL_FILE.exists():
                    os.startfile(str(URL_FILE))
                return
    except Exception:
        pass
    server = tunnel = None
    ready_urls = []
    lock = threading.Lock()
    opened = False

    def read_tunnel(process):
        for line in process.stdout:
            match = re.search(r'https://[a-z0-9-]+\.trycloudflare\.com', line)
            if match:
                with lock:
                    ready_urls.append(match[0])

    def publish_url(host):
        nonlocal opened
        url = host.rstrip('/') + '/' + secret
        URL_FILE.write_text('TifaHop relay base URL (keep private):\n\n' + url +
            '\n\nSet this same RelayURL on your main and all alts.\n' +
            'Quick Tunnel URLs change when the tunnel restarts.\n', encoding='utf-8')
        print('\nYOUR RELAY URL: ' + url + '\nSaved to ' + str(URL_FILE), flush=True)
        if not background and not opened:
            os.startfile(str(URL_FILE))
            opened = True

    try:
        while True:
            if server is None or server.poll() is not None:
                if server is not None:
                    print('Relay exited; restarting in 3 seconds.', flush=True)
                    time.sleep(3)
                server = subprocess.Popen([sys.executable, str(ROOT / 'relay.py'),
                    '--port', str(port), '--secret-file', str(secret_path)], cwd=ROOT,
                    creationflags=CREATE_NO_WINDOW)
                healthy = False
                for _ in range(30):
                    try:
                        with urllib.request.urlopen(health, timeout=1) as response:
                            healthy = json.load(response).get('ok') is True
                        if healthy:
                            break
                    except Exception:
                        time.sleep(.2)
                if not healthy:
                    raise RuntimeError('Relay cannot start. Port may be in use. See relay logs/settings.json.')
            if tunnel is None or tunnel.poll() is not None:
                if tunnel is not None:
                    URL_FILE.write_text('Tunnel reconnecting; waiting for a new URL.\n')
                    print('Tunnel exited; reconnecting in 5 seconds.', flush=True)
                    time.sleep(5)
                args = [str(ROOT / 'cloudflared.exe'), 'tunnel', '--no-autoupdate']
                token = config.get('TunnelToken', '').strip()
                if token:
                    public = config.get('PublicURL', '').strip()
                    if not re.fullmatch(r'https://[A-Za-z0-9.-]+', public):
                        raise ValueError('Named tunnel requires PublicURL such as https://relay.example.com')
                    # Token is inherited in environment, not written in process command line/log.
                    env = dict(os.environ, TUNNEL_TOKEN=token)
                    args += ['run']
                else:
                    env = os.environ.copy()
                    args += ['--url', origin, '--protocol', 'http2']
                tunnel = subprocess.Popen(args, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace',
                    creationflags=CREATE_NO_WINDOW)
                threading.Thread(target=read_tunnel, args=(tunnel,), daemon=True).start()
                if token:
                    publish_url(public)
            with lock:
                urls, ready_urls[:] = ready_urls[:], []
            for url in urls:
                publish_url(url)
            time.sleep(1)
    finally:
        for process in (tunnel, server):
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
        URL_FILE.write_text('Relay stopped. Run START.cmd to get the current URL.\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--background', action='store_true')
    args = parser.parse_args()
    try:
        main(args.background)
    except KeyboardInterrupt:
        pass

"""Small, bounded ntfy-compatible POST /topic and GET /topic/json relay."""
import argparse
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import secrets
import threading
import time
from urllib.parse import urlsplit, parse_qs, unquote


class Store:
    def __init__(self):
        self.lock = threading.Lock()
        self.topics = {}

    def prune(self):
        cutoff = time.time() - 300
        for topic in list(self.topics):
            queue = self.topics[topic]
            while queue and queue[0]['time'] < cutoff:
                queue.popleft()
            if not queue:
                del self.topics[topic]

    def publish(self, topic, message):
        with self.lock:
            self.prune()
            if topic not in self.topics and len(self.topics) >= 256:
                raise ValueError('Too many active topics')
            item = dict(id=secrets.token_hex(8), time=int(time.time()),
                        event='message', topic=topic, message=message)
            self.topics.setdefault(topic, deque(maxlen=256)).append(item)
            return item

    def poll(self, topic, since):
        with self.lock:
            self.prune()
            items = list(self.topics.get(topic, []))
        for index, item in enumerate(items):
            if item['id'] == since:
                return items[index + 1:]
        if since in ('all', '0'):
            return items
        match = re.fullmatch(r'(\d+)([smh])', since or '30s')
        if match:
            seconds = int(match[1]) * {'s': 1, 'm': 60, 'h': 3600}[match[2]]
            return [i for i in items if i['time'] >= time.time() - seconds]
        if since.isdigit():
            return [i for i in items if i['time'] >= int(since)]
        # Unknown/expired ID: replay bounded recent history, clients deduplicate.
        return items


def make_handler(secret, store):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # Do not log secret URLs or account reports.

        def setup(self):
            super().setup()
            self.connection.settimeout(8)

        def reply(self, status, body=b'', content_type='application/json'):
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(body)

        def route(self):
            parsed = urlsplit(self.path)
            parts = [unquote(p) for p in parsed.path.strip('/').split('/')]
            if not parts or not secrets.compare_digest(parts[0], secret):
                self.reply(404)
                return None
            if len(parts) == 2 and parts[1] == 'health':
                return ('health', parsed)
            if len(parts) not in (2, 3) or not re.fullmatch(r'[A-Za-z0-9_-]{1,128}', parts[1]):
                self.reply(404)
                return None
            if len(parts) == 3 and parts[2] != 'json':
                self.reply(404)
                return None
            return (parts[1], parsed)

        def do_GET(self):
            route = self.route()
            if not route:
                return
            topic, parsed = route
            if topic == 'health':
                self.reply(200, b'{"ok":true,"service":"TifaHop relay"}')
                return
            if not parsed.path.endswith('/json'):
                self.reply(404)
                return
            query = parse_qs(parsed.query)
            if query.get('poll') != ['1']:
                self.reply(400, b'{"error":"Use poll=1"}')
                return
            items = store.poll(topic, query.get('since', ['30s'])[0])
            body = ''.join(json.dumps(i, separators=(',', ':')) + '\n' for i in items)
            self.reply(200, body.encode(), 'application/x-ndjson')

        def do_POST(self):
            route = self.route()
            if not route:
                return
            topic, parsed = route
            if topic == 'health' or parsed.path.endswith('/json'):
                self.reply(405)
                return
            try:
                length = int(self.headers.get('Content-Length', '-1'))
                if not 0 < length <= 32768:
                    self.reply(413)
                    return
                raw = self.rfile.read(length)
                if len(raw) != length:
                    self.reply(400)
                    return
                message = raw.decode('utf-8')
                json.loads(message)
                result = store.publish(topic, message)
            except (ValueError, UnicodeError):
                self.reply(400)
                return
            self.reply(200, json.dumps(result).encode())
    return Handler


class Server(ThreadingHTTPServer):
    daemon_threads = True
    def __init__(self, *args):
        self.slots = threading.BoundedSemaphore(64)
        super().__init__(*args)

    def process_request(self, request, address):
        if not self.slots.acquire(blocking=False):
            request.close()
            return
        try:
            super().process_request(request, address)
        except Exception:
            self.slots.release()
            raise

    def process_request_thread(self, request, address):
        try:
            super().process_request_thread(request, address)
        finally:
            self.slots.release()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8787)
    parser.add_argument('--secret-file', required=True)
    args = parser.parse_args()
    secret = Path(args.secret_file).read_text(encoding='utf-8-sig').strip()
    if not re.fullmatch(r'[a-f0-9]{48}', secret):
        raise SystemExit('Invalid relay secret')
    with Server(('127.0.0.1', args.port), make_handler(secret, Store())) as server:
        print('TifaHop relay listening on loopback', flush=True)
        server.serve_forever()

#!/usr/bin/env python3
"""Servidor del cronómetro: sirve la página y guarda los registros en registros.txt.

Solo usa la biblioteca estándar (Python 3.6+, incluido en RHEL 8/9).
Uso:  python3 server.py
Variables opcionales: PORT (8080), HOST (0.0.0.0), DATA (ruta de registros.txt).
"""
import glob
import os
import socketserver
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

DIR = os.path.dirname(os.path.abspath(__file__))
PORT = int(os.environ.get("PORT", "8080"))
HOST = os.environ.get("HOST", "0.0.0.0")
DATA = os.environ.get("DATA", os.path.join(DIR, "registros.txt"))
PAGE = sorted(glob.glob(os.path.join(DIR, "Cron*metro*.html")))[0]
LOCK = threading.Lock()

if not os.path.exists(DATA):
    open(DATA, "wb").close()


def mtime():
    return repr(os.stat(DATA).st_mtime)


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body=b"", ctype=None, head_only=False):
        self.send_response(code)
        if ctype:
            self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        if self.path.split("?")[0] == "/api/registros":
            self.send_header("X-Mtime", mtime())
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body and not head_only:
            self.wfile.write(body)

    def _get(self, head_only):
        url = self.path.split("?")[0]
        if url in ("/", "/index.html"):
            with open(PAGE, "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8", head_only)
        if url == "/api/registros":
            with LOCK, open(DATA, "rb") as f:
                return self._send(200, f.read(), "text/plain; charset=utf-8", head_only)
        self._send(404)

    def do_GET(self):
        self._get(False)

    def do_HEAD(self):
        self._get(True)

    def do_PUT(self):
        if self.path.split("?")[0] != "/api/registros":
            return self._send(404)
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        try:
            with LOCK:
                tmp = DATA + ".tmp"
                with open(tmp, "wb") as f:
                    f.write(body)
                os.replace(tmp, DATA)
            self._send(204)
        except OSError as e:
            self.log_error("No se pudo escribir %s: %s", DATA, e)
            self._send(500)


class Server(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True


if __name__ == "__main__":
    print("Cronómetro en http://%s:%d" % ("127.0.0.1" if HOST == "0.0.0.0" else HOST, PORT), flush=True)
    print("Registros en %s" % DATA, flush=True)
    Server((HOST, PORT), Handler).serve_forever()

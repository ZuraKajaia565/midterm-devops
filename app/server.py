from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, unquote, urlparse
import argparse
import html
import json
import os
import time


APP_VERSION = os.environ.get("APP_VERSION", "local")


def render_page(title, body):
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
  <style>
    body {{ font-family: system-ui, sans-serif; max-width: 760px; margin: 40px auto; padding: 0 20px; line-height: 1.5; }}
    input, button {{ font: inherit; padding: 8px 10px; }}
    button {{ cursor: pointer; }}
    .box {{ border: 1px solid #d0d7de; border-radius: 8px; padding: 16px; margin-top: 16px; }}
    code {{ background: #f6f8fa; padding: 2px 5px; border-radius: 4px; }}
  </style>
</head>
<body>
  <h1>{html.escape(title)}</h1>
  {body}
</body>
</html>"""


def app_response(method, raw_path, body=""):
    parsed = urlparse(raw_path)
    path = parsed.path

    if method == "GET" and path == "/":
        page = render_page(
            "Midterm DevOps App",
            f"""
<p>Running version: <code>{html.escape(APP_VERSION)}</code></p>
<p>Try the dynamic route at <a href="/hello/Zura">/hello/Zura</a>.</p>
<form method="post" action="/message" class="box">
  <label for="message">Message</label>
  <input id="message" name="message" required>
  <button type="submit">Send</button>
</form>""",
        )
        return HTTPStatus.OK, "text/html; charset=utf-8", page.encode()

    if method == "GET" and path.startswith("/hello/"):
        name = unquote(path.removeprefix("/hello/")).strip() or "Guest"
        page = render_page(
            "Dynamic Route",
            f"<p>Hello, <strong>{html.escape(name)}</strong>.</p><p><a href='/'>Back</a></p>",
        )
        return HTTPStatus.OK, "text/html; charset=utf-8", page.encode()

    if method == "POST" and path == "/message":
        fields = parse_qs(body)
        message = fields.get("message", [""])[0].strip()
        safe_message = html.escape(message or "No message provided")
        page = render_page(
            "Submitted",
            f"<div class='box'>Received: <strong>{safe_message}</strong></div><p><a href='/'>Back</a></p>",
        )
        return HTTPStatus.OK, "text/html; charset=utf-8", page.encode()

    if method == "GET" and path == "/health":
        payload = {
            "status": "ok",
            "version": APP_VERSION,
            "timestamp": int(time.time()),
        }
        return HTTPStatus.OK, "application/json", json.dumps(payload).encode()

    return HTTPStatus.NOT_FOUND, "text/plain; charset=utf-8", b"Not found"


class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._handle()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8") if length else ""
        self._handle(body)

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))

    def _handle(self, body=""):
        status, content_type, payload = app_response(self.command, self.path, body)
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main():
    parser = argparse.ArgumentParser(description="Run the Midterm web app")
    parser.add_argument("--host", default=os.environ.get("HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8000")))
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), AppHandler)
    print(f"Serving Midterm app version {APP_VERSION} on http://{args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()

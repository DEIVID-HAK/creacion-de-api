import http.server
import socketserver
import sys

PORT = 8081
NODE_NAME = sys.argv[1] if len(sys.argv) > 1 else "Node-unknown"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = ('{"node": "%s", "status": "HEALTHY"}' % NODE_NAME).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


socketserver.TCPServer(("", PORT), Handler).serve_forever()
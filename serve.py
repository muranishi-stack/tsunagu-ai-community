#!/usr/bin/env python3
"""SPA-friendly HTTP server for Flutter web app.

Serves static files and falls back to index.html for any unknown route
so that Flutter's client-side routing (e.g. /admin/login) works correctly.
"""
import http.server
import socketserver
import os
import sys

PORT = 5060
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')


class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # CORS / iframe headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        # No-cache headers for development
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_GET(self):
        # Strip query string for file existence check
        path = self.path.split('?')[0].split('#')[0]
        # Compute filesystem path
        fs_path = os.path.join(ROOT, path.lstrip('/'))

        # If it's a directory request, fall through to default behavior
        if path == '/' or os.path.isdir(fs_path):
            return super().do_GET()

        # If the file exists, serve it
        if os.path.isfile(fs_path):
            return super().do_GET()

        # Otherwise (SPA route like /admin/login) fall back to index.html
        # Only fall back for "page-like" requests (no extension or .html)
        ext = os.path.splitext(path)[1]
        if ext == '' or ext == '.html':
            self.path = '/index.html'
            return super().do_GET()

        # Real 404 for missing assets (js, png, etc.)
        return super().do_GET()


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == '__main__':
    print(f'Serving {ROOT} on http://0.0.0.0:{PORT}', flush=True)
    with ReusableTCPServer(('0.0.0.0', PORT), SPAHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('Shutting down', flush=True)
            sys.exit(0)

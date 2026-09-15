/** Tiny static file server for previewing `dist/` locally: `npm start`. */
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIST = join(dirname(fileURLToPath(import.meta.url)), '..', 'dist');
const PORT = Number(process.env.PORT) || 4173;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.avif': 'image/avif',
  '.xml': 'application/xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

createServer(async (req, res) => {
  const requested = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  let filePath = join(DIST, normalize(requested).replace(/^(\.\.[/\\])+/, ''));
  try {
    if ((await stat(filePath)).isDirectory()) filePath = join(filePath, 'index.html');
  } catch {
    res.writeHead(404, { 'content-type': 'text/plain' });
    return res.end('Not found');
  }
  try {
    const body = await readFile(filePath);
    res.writeHead(200, { 'content-type': TYPES[extname(filePath)] || 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404, { 'content-type': 'text/plain' });
    res.end('Not found');
  }
}).listen(PORT, () => console.log(`preview: http://localhost:${PORT}`));

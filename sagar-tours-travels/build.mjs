/**
 * Static build: renders every page to `dist/`, copies `public/` alongside it
 * and generates robots.txt + sitemap.xml.
 *
 *   node build.mjs      (or: npm run build)
 */
import { cp, mkdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { HomePage } from './src/pages/home.mjs';
import { PrivacyPage, TermsPage } from './src/pages/legal.mjs';
import { site } from './src/data/site.mjs';
import { resetIcons } from './src/lib/icons.mjs';

const ROOT = dirname(fileURLToPath(import.meta.url));
const DIST = join(ROOT, 'dist');

const PAGES = [
  { file: 'index.html', render: HomePage, url: '/', priority: '1.0' },
  { file: 'privacy.html', render: PrivacyPage },
  { file: 'terms.html', render: TermsPage },
];

function sitemap() {
  const today = new Date().toISOString().slice(0, 10);
  const urls = PAGES.filter((p) => p.url)
    .map(
      (page) => `  <url>
    <loc>${site.origin}${page.url}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>${page.priority}</priority>
  </url>`
    )
    .join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`;
}

const robots = () => `User-agent: *
Allow: /
Disallow: /privacy.html
Disallow: /terms.html

Sitemap: ${site.origin}/sitemap.xml
`;

await rm(DIST, { recursive: true, force: true });
await mkdir(DIST, { recursive: true });
await cp(join(ROOT, 'public'), DIST, { recursive: true });

/**
 * Collapses template indentation. Every run of whitespace containing a newline
 * becomes a single space, which is exactly how a browser already treats it — so
 * this shrinks the file without changing how anything renders. Whitespace
 * between tags is deliberately kept: collapsing it would close up the gaps
 * between inline elements that are not in a flex container.
 */
const tidy = (markup) => markup.replace(/\s*\n\s*/g, ' ').trim() + '\n';

for (const page of PAGES) {
  resetIcons();
  await writeFile(join(DIST, page.file), tidy(page.render()), 'utf8');
}

await writeFile(join(DIST, 'sitemap.xml'), sitemap(), 'utf8');
await writeFile(join(DIST, 'robots.txt'), robots(), 'utf8');

console.log(`built ${PAGES.length} pages → dist/`);

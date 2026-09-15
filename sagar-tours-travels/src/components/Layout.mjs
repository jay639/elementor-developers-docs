/** Document shell: <head>, fonts, structured data and the page chrome. */
import { html, raw, render } from '../lib/html.mjs';
import { site } from '../data/site.mjs';
import { spriteMarkup } from '../lib/icons.mjs';
import { images } from '../data/images.mjs';
import { faqs } from '../data/content.mjs';
import { Header } from './Header.mjs';
import { Footer } from './Footer.mjs';
import { MobileActionBar, FloatingActions } from './MobileActionBar.mjs';

const jsonLd = (data) =>
  raw(
    `<script type="application/ld+json">${JSON.stringify(data).replace(/</g, '\\u003c')}</script>`
  );

/**
 * Structured data for the business.
 *
 * Contact details and the aggregate rating are deliberately omitted while they
 * are placeholders — publishing unverified values as structured data would be
 * making a claim to search engines that nobody has confirmed.
 */
function businessSchema() {
  const business = {
    '@context': 'https://schema.org',
    '@type': 'TaxiService',
    name: site.name,
    description: site.seo.description,
    url: site.origin,
    areaServed: [
      { '@type': 'City', name: 'Nagpur' },
      { '@type': 'State', name: 'Maharashtra' },
    ],
    provider: {
      '@type': 'LocalBusiness',
      name: site.name,
      address: {
        '@type': 'PostalAddress',
        addressLocality: site.city,
        addressRegion: site.state,
        addressCountry: 'IN',
      },
    },
  };

  if (!site.contact.isPlaceholder) {
    business.telephone = site.contact.phoneDisplay;
    business.provider.telephone = site.contact.phoneDisplay;
    business.provider.email = site.contact.email;
    business.provider.address.streetAddress = site.contact.addressLines[0];
  }

  return business;
}

function faqSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((item) => ({
      '@type': 'Question',
      name: item.q,
      acceptedAnswer: { '@type': 'Answer', text: item.a },
    })),
  };
}

export function Layout({
  title,
  description,
  path = '/',
  children,
  schema = [],
  bodyClass = '',
  noindex = false,
}) {
  const canonical = `${site.origin}${path}`;
  const ogImage = `${site.origin}/${images.og.src}`;

  /* Render the body first so the icon sprite knows which symbols to emit. */
  const body = [render(Header()), `<main id="main">${render(children)}</main>`, render(Footer()), render(MobileActionBar()), render(FloatingActions())].join('\n');
  const sprite = spriteMarkup();

  return `<!doctype html>
<html lang="en-IN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${title}</title>
<meta name="description" content="${description}">
<meta name="theme-color" content="#C62828">
<link rel="canonical" href="${canonical}">
${noindex ? '<meta name="robots" content="noindex, follow">' : '<meta name="robots" content="index, follow, max-image-preview:large">'}

<meta property="og:type" content="website">
<meta property="og:site_name" content="${site.name}">
<meta property="og:locale" content="${site.seo.locale}">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${description}">
<meta property="og:url" content="${canonical}">
<meta property="og:image" content="${ogImage}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${description}">
<meta name="twitter:image" content="${ogImage}">

<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="favicon.svg">

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preload" as="style" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" media="print" onload="this.media='all'">
<noscript><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"></noscript>

<link rel="stylesheet" href="css/styles.css">
${[businessSchema(), ...schema].map((s) => render(jsonLd(s))).join('\n')}
</head>
<body class="${bodyClass}">
${sprite}
<a class="skip-link" href="#main">Skip to main content</a>
${body}
<script src="js/app.js" defer></script>
</body>
</html>
`;
}

export { faqSchema };

/**
 * Global site configuration for Sagar Tours and Travels.
 *
 * ──────────────────────────────────────────────────────────────────────────
 * PLACEHOLDERS
 * Every value below marked with `PLACEHOLDER` is a stand-in. Nothing here has
 * been verified with the business. Replace the values, set the matching
 * `*IsPlaceholder` flag to `false`, and run `npm run build` — the templates
 * automatically drop the "to be confirmed" chips once the flag is false.
 * ──────────────────────────────────────────────────────────────────────────
 */

/** Digits only, in international format. Used to build tel: and wa.me links. */
const PHONE_E164 = '+910000000000'; // PLACEHOLDER
const WHATSAPP_E164 = '+910000000000'; // PLACEHOLDER

export const site = {
  name: 'Sagar Tours and Travels',
  shortName: 'Sagar Tours',
  tagline: 'Taxi Service | Cab Service | Tours & Travels',
  city: 'Nagpur',
  state: 'Maharashtra',
  country: 'India',

  /** Production origin. Used for canonical URLs, Open Graph and sitemap.xml. */
  origin: 'https://www.sagartoursandtravels.example', // PLACEHOLDER

  contact: {
    /** Flip to false once real details are supplied. */
    isPlaceholder: true,
    phoneDisplay: '+91 00000 00000', // PLACEHOLDER
    phoneHref: `tel:${PHONE_E164}`,
    whatsappDisplay: '+91 00000 00000', // PLACEHOLDER
    whatsappHref: `https://wa.me/${WHATSAPP_E164.replace('+', '')}`,
    email: 'hello@example.com', // PLACEHOLDER
    emailHref: 'mailto:hello@example.com',
    addressLines: [
      'Office address line 1', // PLACEHOLDER
      'Nagpur, Maharashtra 440001',
    ],
    hours: 'Open 24 hours, 7 days a week',
    /** Google Maps embed URL. Replace with the business listing embed. */
    mapEmbed:
      'https://www.google.com/maps?q=Nagpur,Maharashtra,India&output=embed',
    mapLink: 'https://www.google.com/maps/search/?api=1&query=Nagpur%2CMaharashtra',
    /** Google Business Profile reviews link. PLACEHOLDER */
    googleReviewsUrl: '#reviews',
  },

  nav: [
    { label: 'Home', href: '#home' },
    { label: 'About Us', href: '#about' },
    { label: 'Services', href: '#services' },
    { label: 'Our Fleet', href: '#fleet' },
    { label: 'Popular Routes', href: '#routes' },
    { label: 'Reviews', href: '#reviews' },
    { label: 'Contact', href: '#contact' },
  ],

  seo: {
    title:
      'Taxi Service in Nagpur | Airport & Outstation Cabs — Sagar Tours and Travels',
    description:
      'Sagar Tours and Travels offers reliable taxi service in Nagpur for local travel, airport transfers, one-way and outstation journeys, with professional drivers and clean, comfortable cars.',
    keywords: [
      'taxi service in Nagpur',
      'cab service in Nagpur',
      'airport taxi Nagpur',
      'outstation taxi Nagpur',
      'one way taxi Nagpur',
      'local taxi Nagpur',
      'taxi booking Nagpur',
    ],
    locale: 'en_IN',
  },

  legal: {
    year: new Date().getFullYear(),
  },
};

/** Builds a pre-filled WhatsApp link. */
export function whatsappLink(message) {
  const base = site.contact.whatsappHref;
  return message ? `${base}?text=${encodeURIComponent(message)}` : base;
}

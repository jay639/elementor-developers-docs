/** Contact cards, address panel and map. */
import { html, raw } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { SectionHeading, PlaceholderChip, PlaceholderNote } from './ui.mjs';
import { site } from '../data/site.mjs';

export function ContactCard({ iconName, label, value, href, external = false, isPlaceholder }) {
  return html`<article class="card card--contact">
    <span class="card__icon">${icon(iconName, { size: 24 })}</span>
    <h3 class="card__title">${label}</h3>
    <a
      class="contact__value"
      href="${href}"
      ${external ? raw('target="_blank" rel="noopener"') : ''}
      >${value}</a
    >
    ${isPlaceholder ? PlaceholderChip({}) : ''}
  </article>`;
}

export function ContactSection() {
  const { contact } = site;
  return html`<section class="section section--alt" id="contact" aria-labelledby="contactTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Contact',
        title: `Get in Touch with ${site.name}`,
        subtitle: 'Call, message or send your trip details — whichever is quickest for you.',
        id: 'contactTitle',
      })}

      <div class="grid grid--contact" data-reveal>
        ${ContactCard({
          iconName: 'phone',
          label: 'Call Us',
          value: contact.phoneDisplay,
          href: contact.phoneHref,
          isPlaceholder: contact.isPlaceholder,
        })}
        ${ContactCard({
          iconName: 'whatsapp',
          label: 'WhatsApp',
          value: contact.whatsappDisplay,
          href: contact.whatsappHref,
          external: true,
          isPlaceholder: contact.isPlaceholder,
        })}
        ${ContactCard({
          iconName: 'mail',
          label: 'Email',
          value: contact.email,
          href: contact.emailHref,
          isPlaceholder: contact.isPlaceholder,
        })}
      </div>

      <div class="contact-panel" data-reveal>
        <div class="contact-panel__info">
          <h3 class="contact-panel__title">${icon('location', { size: 20 })} Office Address</h3>
          <address class="contact-panel__address">
            ${contact.addressLines.map((line) => html`<span>${line}</span>`)}
          </address>
          ${contact.isPlaceholder ? PlaceholderChip({}) : ''}

          <h3 class="contact-panel__title">${icon('clock', { size: 20 })} Business Hours</h3>
          <p class="contact-panel__hours">${contact.hours}</p>

          <a class="contact-panel__maplink" href="${contact.mapLink}" target="_blank" rel="noopener"
            >Open in Google Maps ${icon('arrowUpRight', { size: 18 })}</a
          >
        </div>
        <div class="contact-panel__map">
          ${raw(`<iframe
            src="${contact.mapEmbed}"
            title="Map showing the ${site.name} service area in Nagpur"
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            allowfullscreen></iframe>`)}
        </div>
      </div>

      ${contact.isPlaceholder
        ? PlaceholderNote({
            text: 'Phone number, WhatsApp number, email address and office address are placeholders. Replace them in src/data/site.mjs before publishing.',
          })
        : ''}
    </div>
  </section>`;
}

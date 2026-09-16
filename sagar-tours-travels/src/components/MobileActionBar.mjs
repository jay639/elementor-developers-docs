/** Fixed bottom bar on phones + floating call/WhatsApp buttons on desktop. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { site, whatsappLink } from '../data/site.mjs';

const WHATSAPP_MESSAGE = `Hi ${site.name}, I would like to book a taxi in Nagpur.`;

export function MobileActionBar() {
  return html`<div class="action-bar" role="group" aria-label="Quick actions">
    <a class="action-bar__item" href="${site.contact.phoneHref}">
      ${icon('phone', { size: 22 })}<span>Call</span>
    </a>
    <a
      class="action-bar__item action-bar__item--whatsapp"
      href="${whatsappLink(WHATSAPP_MESSAGE)}"
      target="_blank"
      rel="noopener"
    >
      ${icon('whatsapp', { size: 22 })}<span>WhatsApp</span>
    </a>
    <a class="action-bar__item action-bar__item--primary" href="#booking">
      ${icon('calendar', { size: 22 })}<span>Book Now</span>
    </a>
  </div>`;
}

export function FloatingActions() {
  return html`<div class="fab-stack" aria-label="Contact shortcuts">
    <a
      class="fab fab--whatsapp"
      href="${whatsappLink(WHATSAPP_MESSAGE)}"
      target="_blank"
      rel="noopener"
      aria-label="Message us on WhatsApp"
    >
      ${icon('whatsapp', { size: 26 })}
      <span class="fab__tip">WhatsApp us</span>
    </a>
    <a class="fab fab--call" href="${site.contact.phoneHref}" aria-label="Call us now">
      ${icon('phone', { size: 24 })}
      <span class="fab__tip">Call now</span>
    </a>
  </div>`;
}

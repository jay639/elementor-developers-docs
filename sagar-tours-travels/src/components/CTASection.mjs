/** Dark, image-backed closing call to action. */
import { html } from '../lib/html.mjs';
import { Button, Img } from './ui.mjs';
import { site, whatsappLink } from '../data/site.mjs';

export function CTASection() {
  return html`<section class="cta" aria-labelledby="ctaTitle">
    <div class="cta__media" aria-hidden="true">
      ${Img('cta', { alt: '', sizes: '100vw' })}
      <span class="cta__scrim"></span>
    </div>
    <div class="container cta__inner" data-reveal>
      <h2 class="cta__title" id="ctaTitle">Ready for a Comfortable Ride?</h2>
      <p class="cta__lead">
        Book your taxi with ${site.name} and travel from Nagpur with comfort and confidence.
      </p>
      <div class="cta__actions">
        ${Button({
          label: 'Book Your Taxi',
          href: '#booking',
          variant: 'filled',
          size: 'lg',
          iconAfter: 'arrowRight',
        })}
        ${Button({
          label: 'WhatsApp Us',
          href: whatsappLink(`Hi ${site.name}, I would like to book a taxi.`),
          variant: 'whatsapp',
          size: 'lg',
          iconName: 'whatsapp',
          attrs: 'target="_blank" rel="noopener"',
        })}
        ${Button({
          label: 'Call Now',
          href: site.contact.phoneHref,
          variant: 'ghost',
          size: 'lg',
          iconName: 'phone',
        })}
      </div>
    </div>
  </section>`;
}

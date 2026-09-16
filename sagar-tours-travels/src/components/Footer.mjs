/** Four-column footer with brand, services, routes and contact details. */
import { html } from '../lib/html.mjs';
import { icon, logoMark } from '../lib/icons.mjs';
import { site } from '../data/site.mjs';
import { footerServices, footerRoutes, services, routes } from '../data/content.mjs';

/** Maps a footer label back to the on-page anchor it should scroll to. */
const serviceAnchor = (label) => {
  const match = services.find((s) => label.toLowerCase().startsWith(s.title.toLowerCase().slice(0, 8)));
  return match ? `#service-${match.id}` : '#services';
};

const routeAnchor = (label) => {
  const destination = label.replace(/^Nagpur to\s+/i, '').trim().toLowerCase();
  const match = routes.find((r) => r.to.toLowerCase() === destination);
  return match ? '#routes' : '#routes';
};

export function Footer() {
  const { contact } = site;
  return html`<footer class="site-footer">
    <div class="container site-footer__grid">
      <div class="site-footer__col site-footer__col--brand">
        <div class="brand brand--footer">
          ${logoMark({ size: 44 })}
          <span class="brand__text">
            <span class="brand__name">Sagar <em>Tours &amp; Travels</em></span>
            <span class="brand__sub">Taxi &amp; Travel Service, Nagpur</span>
          </span>
        </div>
        <p class="site-footer__about">
          Reliable taxi and travel services in Nagpur for local, airport and outstation journeys.
        </p>
        <div class="site-footer__social">
          <a class="icon-btn icon-btn--ghost" href="${contact.phoneHref}" aria-label="Call us"
            >${icon('phone', { size: 20 })}</a
          >
          <a
            class="icon-btn icon-btn--ghost"
            href="${contact.whatsappHref}"
            target="_blank"
            rel="noopener"
            aria-label="WhatsApp us"
            >${icon('whatsapp', { size: 20 })}</a
          >
          <a class="icon-btn icon-btn--ghost" href="${contact.emailHref}" aria-label="Email us"
            >${icon('mail', { size: 20 })}</a
          >
        </div>
      </div>

      <nav class="site-footer__col" aria-labelledby="footerServices">
        <h2 class="site-footer__title" id="footerServices">Services</h2>
        <ul class="site-footer__list">
          ${footerServices.map(
            (label) => html`<li><a href="${serviceAnchor(label)}">${label}</a></li>`
          )}
        </ul>
      </nav>

      <nav class="site-footer__col" aria-labelledby="footerRoutes">
        <h2 class="site-footer__title" id="footerRoutes">Popular Routes</h2>
        <ul class="site-footer__list">
          ${footerRoutes.map((label) => html`<li><a href="${routeAnchor(label)}">${label}</a></li>`)}
        </ul>
      </nav>

      <div class="site-footer__col" aria-labelledby="footerContact">
        <h2 class="site-footer__title" id="footerContact">Contact</h2>
        <ul class="site-footer__list site-footer__list--contact">
          <li>
            <a href="${contact.phoneHref}">${icon('phone', { size: 18 })}${contact.phoneDisplay}</a>
          </li>
          <li>
            <a href="${contact.whatsappHref}" target="_blank" rel="noopener"
              >${icon('whatsapp', { size: 18 })}${contact.whatsappDisplay}</a
            >
          </li>
          <li><a href="${contact.emailHref}">${icon('mail', { size: 18 })}${contact.email}</a></li>
          <li class="site-footer__address">
            ${icon('location', { size: 18 })}
            <address>${contact.addressLines.map((line) => html`<span>${line}</span>`)}</address>
          </li>
        </ul>
      </div>
    </div>

    <div class="site-footer__bar">
      <div class="container site-footer__barInner">
        <p>&copy; ${site.legal.year} ${site.name}. All Rights Reserved.</p>
        <p class="site-footer__legal">
          <a href="privacy.html">Privacy Policy</a>
          <span aria-hidden="true">|</span>
          <a href="terms.html">Terms &amp; Conditions</a>
        </p>
      </div>
    </div>
  </footer>`;
}

/** Sticky site header: brand, desktop nav, quick-contact icons, mobile drawer. */
import { html } from '../lib/html.mjs';
import { icon, logoMark } from '../lib/icons.mjs';
import { Button } from './ui.mjs';
import { site } from '../data/site.mjs';

function Brand({ compact = false } = {}) {
  return html`<a class="brand" href="#home" aria-label="${site.name} — home">
    ${logoMark({ size: compact ? 36 : 42 })}
    <span class="brand__text">
      <span class="brand__name">Sagar <em>Tours &amp; Travels</em></span>
      <span class="brand__sub">Taxi &amp; Travel Service, Nagpur</span>
    </span>
  </a>`;
}

export function Header() {
  const navItems = site.nav.map(
    (item) => html`<li>
      <a class="nav__link" href="${item.href}" data-nav-link>${item.label}</a>
    </li>`
  );

  return html`<header class="site-header" id="siteHeader" data-header>
    <div class="container site-header__inner">
      ${Brand()}

      <nav class="nav" aria-label="Primary">
        <ul class="nav__list">
          ${navItems}
        </ul>
      </nav>

      <div class="site-header__actions">
        <a
          class="icon-btn icon-btn--call"
          href="${site.contact.phoneHref}"
          aria-label="Call ${site.name}"
        >
          ${icon('phone', { size: 22 })}
        </a>
        <a
          class="icon-btn icon-btn--whatsapp"
          href="${site.contact.whatsappHref}"
          target="_blank"
          rel="noopener"
          aria-label="Message ${site.name} on WhatsApp"
        >
          ${icon('whatsapp', { size: 22 })}
        </a>
        ${Button({
          label: 'Book a Taxi',
          href: '#booking',
          variant: 'filled',
          size: 'sm',
          className: 'site-header__cta',
        })}
        <button
          class="icon-btn icon-btn--menu"
          type="button"
          aria-label="Open navigation menu"
          aria-expanded="false"
          aria-controls="mobileNav"
          data-menu-toggle
        >
          ${icon('menu', { size: 24, className: 'icon-menu' })}
          ${icon('close', { size: 24, className: 'icon-close' })}
        </button>
      </div>
    </div>

    <div class="nav-drawer" id="mobileNav" data-drawer hidden>
      <nav aria-label="Mobile">
        <ul class="nav-drawer__list">
          ${site.nav.map(
            (item) => html`<li>
              <a class="nav-drawer__link" href="${item.href}" data-drawer-link
                >${item.label}${icon('arrowRight', { size: 18 })}</a
              >
            </li>`
          )}
        </ul>
      </nav>
      <div class="nav-drawer__footer">
        ${Button({
          label: 'Book a Taxi',
          href: '#booking',
          variant: 'filled',
          block: true,
          iconName: 'calendar',
          attrs: 'data-drawer-link',
        })}
        <div class="nav-drawer__contact">
          <a href="${site.contact.phoneHref}">${icon('phone', { size: 18 })} ${site.contact.phoneDisplay}</a>
          <a href="${site.contact.whatsappHref}" target="_blank" rel="noopener"
            >${icon('whatsapp', { size: 18 })} WhatsApp</a
          >
        </div>
      </div>
    </div>
    <div class="nav-scrim" data-scrim hidden></div>
  </header>`;
}

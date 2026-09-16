/** FAQ accordion built on native <details> so it works without JavaScript. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { SectionHeading } from './ui.mjs';
import { faqs } from '../data/content.mjs';

export function FAQAccordion({ items = faqs }) {
  return html`<div class="accordion" data-accordion>
    ${items.map(
      (item, index) => html`<details class="accordion__item" ${index === 0 ? '' : ''}>
        <summary class="accordion__summary">
          <span class="accordion__question">${item.q}</span>
          <span class="accordion__marker" aria-hidden="true">${icon('chevronDown', { size: 20 })}</span>
        </summary>
        <div class="accordion__panel"><p>${item.a}</p></div>
      </details>`
    )}
  </div>`;
}

export function FAQSection() {
  return html`<section class="section" id="faq" aria-labelledby="faqTitle">
    <div class="container container--narrow">
      ${SectionHeading({
        eyebrow: 'Good to Know',
        title: 'Frequently Asked Questions',
        subtitle: 'Still unsure about something? Call or message us and we will answer directly.',
        id: 'faqTitle',
      })}
      <div data-reveal>${FAQAccordion({})}</div>
    </div>
  </section>`;
}

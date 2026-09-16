/** "Your Trusted Taxi Partner in Nagpur" two-column section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Button, Img } from './ui.mjs';
import { aboutParagraphs } from '../data/content.mjs';

const HIGHLIGHTS = [
  { icon: 'location', label: 'Based in Nagpur' },
  { icon: 'flight', label: 'Airport & railway transfers' },
  { icon: 'route', label: 'Local & outstation travel' },
  { icon: 'headset', label: 'Booking support on call' },
];

export function About() {
  return html`<section class="section" id="about" aria-labelledby="aboutTitle">
    <div class="container split split--reverse">
      <div class="split__media" data-reveal>
        <div class="media-frame media-frame--tall">
          ${Img('about', { sizes: '(max-width: 960px) 100vw, 45vw' })}
        </div>
      </div>
      <div class="split__body" data-reveal>
        <p class="eyebrow">About Us</p>
        <h2 class="split__title" id="aboutTitle">Your Trusted Taxi Partner in Nagpur</h2>
        ${aboutParagraphs.map((paragraph) => html`<p class="split__text">${paragraph}</p>`)}
        <ul class="pill-list">
          ${HIGHLIGHTS.map(
            (item) => html`<li class="pill">${icon(item.icon, { size: 18 })}<span>${item.label}</span></li>`
          )}
        </ul>
        ${Button({
          label: 'Know More About Us',
          href: '#contact',
          variant: 'outlined',
          size: 'lg',
          iconAfter: 'arrowRight',
          className: 'split__cta',
        })}
      </div>
    </div>
  </section>`;
}

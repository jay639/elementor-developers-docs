/** Four-up statistics strip that overlaps the bottom of the hero. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { PlaceholderNote } from './ui.mjs';
import { stats } from '../data/content.mjs';

export function TrustStats() {
  return html`<section class="stats" aria-label="Service highlights">
    <div class="container">
      <div class="stats__grid" data-reveal>
        ${stats.items.map(
          (item) => html`<article class="stat">
            <span class="stat__icon">${icon(item.icon, { size: 26 })}</span>
            <p class="stat__value">
              ${item.value}${!item.verified && stats.isPlaceholder
                ? html`<sup class="stat__flag" title="Placeholder figure — pending confirmation"
                    >*</sup
                  >`
                : ''}
            </p>
            <p class="stat__label">${item.label}</p>
          </article>`
        )}
      </div>
      ${stats.isPlaceholder ? PlaceholderNote({ text: stats.note }) : ''}
    </div>
  </section>`;
}

/**
 * Google reviews section.
 *
 * The cards are deliberately empty of testimonial text: inventing reviews for a
 * real business is not acceptable, so each card renders as a labelled
 * placeholder until real reviews are imported from the Google Business Profile.
 */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Button, SectionHeading, Stars, PlaceholderChip, PlaceholderNote } from './ui.mjs';
import { reviews } from '../data/content.mjs';
import { site } from '../data/site.mjs';

export function ReviewCard({ review, isPlaceholder = false }) {
  return html`<article class="card card--review${isPlaceholder ? ' is-placeholder' : ''}">
    <span class="review__quote" aria-hidden="true">${icon('quote', { size: 28 })}</span>
    ${Stars({ count: 5, label: '5 out of 5 stars' })}
    <p class="review__body">${review.body}</p>
    <footer class="review__foot">
      <span class="review__avatar" aria-hidden="true">${icon('person', { size: 20 })}</span>
      <span class="review__meta">
        <span class="review__name">${review.name}</span>
        ${review.service ? html`<span class="review__service">${review.service}</span>` : ''}
      </span>
      ${isPlaceholder ? PlaceholderChip({ label: 'Placeholder' }) : ''}
    </footer>
  </article>`;
}

export function ReviewsSection() {
  return html`<section class="section section--alt" id="reviews" aria-labelledby="reviewsTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Reviews',
        title: 'What Our Customers Say',
        id: 'reviewsTitle',
      })}
      <div class="rating-summary${reviews.isPlaceholder ? ' is-placeholder' : ''}" data-reveal>
        ${Stars({ count: 5, label: 'Rated 4.9 out of 5' })}
        <p class="rating-summary__value">
          ${reviews.rating}
          ${reviews.isPlaceholder ? PlaceholderChip({ label: 'Unverified' }) : ''}
        </p>
        <p class="rating-summary__label">Google Rating</p>
      </div>
      <div class="grid grid--reviews" data-reveal>
        ${reviews.items.map((review) =>
          ReviewCard({ review, isPlaceholder: reviews.isPlaceholder })
        )}
      </div>
      ${reviews.isPlaceholder ? PlaceholderNote({ text: reviews.note }) : ''}
      <div class="section__cta">
        ${Button({
          label: 'View All Google Reviews',
          href: site.contact.googleReviewsUrl,
          variant: 'outlined',
          size: 'lg',
          iconAfter: 'arrowUpRight',
        })}
      </div>
    </div>
  </section>`;
}

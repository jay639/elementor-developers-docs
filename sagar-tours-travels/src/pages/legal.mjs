/**
 * Privacy Policy and Terms & Conditions.
 *
 * These are drafting templates, not legal advice. They are marked `noindex`
 * and carry a visible notice so they cannot be mistaken for reviewed policies.
 */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Layout } from '../components/Layout.mjs';
import { site } from '../data/site.mjs';

function LegalPage({ title, intro, sections, path, description }) {
  return Layout({
    title: `${title} | ${site.name}`,
    description,
    path,
    noindex: true,
    bodyClass: 'page--legal',
    children: html`<section class="section legal">
      <div class="container container--narrow">
        <header class="legal__head">
          <p class="eyebrow">${site.name}</p>
          <h1 class="legal__title">${title}</h1>
          <p class="legal__intro">${intro}</p>
          <p class="placeholder-note placeholder-note--boxed">
            ${icon('shield', { size: 18 })}
            <span
              >Draft template. This page has not been reviewed by a legal professional and uses
              placeholder business details. Have it reviewed and update
              <code>src/data/site.mjs</code> before publishing.</span
            >
          </p>
        </header>

        ${sections.map(
          (section) => html`<article class="legal__section">
            <h2>${section.heading}</h2>
            ${section.body.map((paragraph) => html`<p>${paragraph}</p>`)}
          </article>`
        )}

        <p class="legal__back">
          <a href="index.html">${icon('arrowRight', { size: 18 })} Back to the home page</a>
        </p>
      </div>
    </section>`,
  });
}

export function PrivacyPage() {
  return LegalPage({
    title: 'Privacy Policy',
    path: '/privacy.html',
    description: `How ${site.name} handles the information you share when you request a taxi booking.`,
    intro: `This policy explains what ${site.name} collects when you request a booking, why it is collected, and how long it is kept.`,
    sections: [
      {
        heading: 'Information we collect',
        body: [
          'When you submit the booking form, send a WhatsApp message or call us, we receive the details you choose to share: your name, mobile number, pickup and drop locations, travel date and time, and the vehicle you prefer.',
          'We do not ask for payment card details through this website.',
        ],
      },
      {
        heading: 'How we use it',
        body: [
          'Your details are used to prepare a fare, confirm your booking, assign a driver and contact you about that trip. We may contact you about the same booking if plans change.',
          'We do not sell your details to third parties.',
        ],
      },
      {
        heading: 'Sharing',
        body: [
          'Trip details are shared with the driver assigned to your journey so they can reach the pickup point. Where a booking is passed to a partner operator, only the details needed to complete the trip are shared.',
        ],
      },
      {
        heading: 'Third-party services',
        body: [
          'This site embeds a Google Maps frame and links out to WhatsApp. Those services have their own privacy policies and may collect data when you interact with them.',
          'Web fonts are served by Google Fonts.',
        ],
      },
      {
        heading: 'Retention',
        body: [
          'Booking records are kept only as long as needed to run the service and meet record-keeping obligations. [Specify the retention period before publishing.]',
        ],
      },
      {
        heading: 'Your choices',
        body: [
          `To ask what we hold about you, to correct it, or to have it deleted, contact us at ${site.contact.email} or on ${site.contact.phoneDisplay}.`,
        ],
      },
    ],
  });
}

export function TermsPage() {
  return LegalPage({
    title: 'Terms & Conditions',
    path: '/terms.html',
    description: `The terms that apply to taxi bookings made with ${site.name}.`,
    intro: `These terms apply to bookings made with ${site.name} through this website, by phone or on WhatsApp.`,
    sections: [
      {
        heading: 'Bookings and confirmation',
        body: [
          'Submitting the booking form or sending a message is a request, not a confirmed booking. A booking is confirmed only once we respond and confirm the vehicle, the fare and the pickup time.',
          'Vehicle models shown on this site indicate the category available. The exact model may vary depending on availability on your travel date.',
        ],
      },
      {
        heading: 'Fares and charges',
        body: [
          'Fares are quoted per trip based on distance, vehicle category and trip type. Tolls, state permits, parking and driver allowances are generally charged separately unless your quote states otherwise.',
          'Waiting time beyond the agreed pickup window may be charged. [Confirm the waiting-time policy before publishing.]',
        ],
      },
      {
        heading: 'Cancellations and changes',
        body: [
          'Let us know as early as you can if plans change so the vehicle can be reassigned. [Specify the cancellation window and any charges before publishing.]',
        ],
      },
      {
        heading: 'Passenger responsibilities',
        body: [
          'Passengers are asked to follow applicable road safety laws, including seat belt use. Smoking and consumption of alcohol in the vehicle are not permitted. Damage to the vehicle caused by a passenger may be charged.',
          'Please check for personal belongings before leaving the vehicle.',
        ],
      },
      {
        heading: 'Delays and circumstances beyond our control',
        body: [
          'We aim for punctual pickups, but traffic, weather, road closures and vehicle breakdowns can cause delays. Where a delay is outside our control, we will arrange a replacement vehicle where possible.',
        ],
      },
      {
        heading: 'Contact',
        body: [
          `Questions about these terms can be sent to ${site.contact.email} or raised on ${site.contact.phoneDisplay}.`,
        ],
      },
    ],
  });
}

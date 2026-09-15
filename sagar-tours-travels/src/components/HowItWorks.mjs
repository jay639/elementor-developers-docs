/** Four-step Material-style stepper. */
import { html } from '../lib/html.mjs';
import { Button, SectionHeading } from './ui.mjs';
import { steps } from '../data/content.mjs';

export function HowItWorks() {
  return html`<section class="section section--alt" id="how-it-works" aria-labelledby="howTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'How It Works',
        title: 'Book Your Taxi in 4 Simple Steps',
        subtitle: 'From the first message to the pickup point, the process stays short.',
        id: 'howTitle',
      })}
      <ol class="stepper" data-reveal>
        ${steps.map(
          (step) => html`<li class="step">
            <span class="step__number" aria-hidden="true">${step.number}</span>
            <div class="step__body">
              <h3 class="step__title"><span class="sr-only">Step ${step.number}: </span>${step.title}</h3>
              <p class="step__text">${step.description}</p>
            </div>
          </li>`
        )}
      </ol>
      <div class="stepper__cta">
        ${Button({
          label: 'Start Your Booking',
          href: '#booking',
          variant: 'filled',
          size: 'lg',
          iconAfter: 'arrowRight',
        })}
      </div>
    </div>
  </section>`;
}

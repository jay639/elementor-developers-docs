/** Material-style outlined booking card used in the hero. */
import { html, raw } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Button } from './ui.mjs';
import { fleet } from '../data/content.mjs';
import { site } from '../data/site.mjs';

/**
 * Outlined text field. `floated` forces the label up for controls that always
 * render a value (date, time, select), where `:placeholder-shown` never matches.
 */
function Field({
  id,
  label,
  type = 'text',
  iconName,
  required = false,
  attrs = '',
  floated = false,
  autocomplete,
  help,
}) {
  return html`<div class="field${floated ? ' field--floated' : ''}">
    ${iconName ? icon(iconName, { size: 20, className: 'field__icon' }) : ''}
    <input
      class="field__control"
      id="${id}"
      name="${id}"
      type="${type}"
      placeholder=" "
      ${required ? raw('required') : ''}
      ${autocomplete ? raw(`autocomplete="${autocomplete}"`) : ''}
      ${help ? raw(`aria-describedby="${id}-help"`) : ''}
      ${raw(attrs)}
    />
    <label class="field__label" for="${id}">${label}${required ? raw('<span aria-hidden="true"> *</span>') : ''}</label>
    <span class="field__outline" aria-hidden="true"></span>
    ${help ? html`<small class="field__help" id="${id}-help">${help}</small>` : ''}
    <small class="field__error" data-error-for="${id}" hidden></small>
  </div>`;
}

function SelectField({ id, label, iconName, options, required = false }) {
  return html`<div class="field field--floated field--select">
    ${iconName ? icon(iconName, { size: 20, className: 'field__icon' }) : ''}
    <select class="field__control" id="${id}" name="${id}" ${required ? raw('required') : ''}>
      ${options.map(
        (option) =>
          html`<option value="${option.value}" ${option.value === '' ? raw('selected') : ''}>
            ${option.label}
          </option>`
      )}
    </select>
    <label class="field__label" for="${id}">${label}</label>
    <span class="field__outline" aria-hidden="true"></span>
    ${icon('chevronDown', { size: 20, className: 'field__chevron' })}
    <small class="field__error" data-error-for="${id}" hidden></small>
  </div>`;
}

export function BookingForm() {
  const vehicleOptions = [
    { value: '', label: 'Any vehicle' },
    ...fleet.map((v) => ({ value: v.name, label: `${v.name} · ${v.category}` })),
  ];

  return html`<section class="booking-card" id="booking" aria-labelledby="bookingTitle">
    <div class="booking-card__head">
      <h2 class="booking-card__title" id="bookingTitle">Book Your Taxi</h2>
      <p class="booking-card__sub">Share your trip details and we will come back with a fare.</p>
    </div>

    <form class="booking-form" data-booking-form novalidate>
      <div class="booking-form__grid">
        ${Field({
          id: 'pickup',
          label: 'Pickup Location',
          iconName: 'location',
          required: true,
          autocomplete: 'address-level2',
        })}
        ${Field({
          id: 'drop',
          label: 'Drop Location',
          iconName: 'route',
          required: true,
        })}
        ${Field({
          id: 'date',
          label: 'Travel Date',
          type: 'date',
          iconName: 'calendar',
          required: true,
          floated: true,
        })}
        ${Field({
          id: 'time',
          label: 'Pickup Time',
          type: 'time',
          iconName: 'clock',
          required: true,
          floated: true,
        })}
        ${SelectField({
          id: 'vehicle',
          label: 'Select Vehicle',
          iconName: 'car',
          options: vehicleOptions,
        })}
        ${Field({
          id: 'mobile',
          label: 'Mobile Number',
          type: 'tel',
          iconName: 'phone',
          required: true,
          autocomplete: 'tel',
          attrs: 'inputmode="numeric" maxlength="15"',
        })}
      </div>

      <div class="booking-form__actions">
        ${Button({
          label: 'Get a Quote',
          type: 'submit',
          variant: 'filled',
          size: 'lg',
          iconName: 'send',
          block: true,
        })}
        ${Button({
          label: 'Book on WhatsApp',
          variant: 'whatsapp',
          size: 'lg',
          iconName: 'whatsapp',
          block: true,
          attrs: `data-booking-whatsapp data-wa-base="${site.contact.whatsappHref}" target="_blank" rel="noopener"`,
          href: site.contact.whatsappHref,
        })}
      </div>

      <p class="booking-form__note">
        ${icon('shield', { size: 16 })}
        <span>Your details are used only to respond to this booking request.</span>
      </p>
      <p class="booking-form__status" data-booking-status role="status" aria-live="polite"></p>
    </form>
  </section>`;
}

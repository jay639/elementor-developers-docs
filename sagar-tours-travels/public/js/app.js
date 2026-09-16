/*!
 * Sagar Tours and Travels — front-end behaviour.
 * No dependencies. Everything degrades gracefully if this file fails to load:
 * the nav links, the FAQ accordion and every call/WhatsApp link work without it.
 */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (selector, scope) {
    return (scope || document).querySelector(selector);
  };
  var $$ = function (selector, scope) {
    return Array.prototype.slice.call((scope || document).querySelectorAll(selector));
  };

  /* ---------------------------------------------------------------- header */
  (function header() {
    var el = $('[data-header]');
    if (!el) return;

    var ticking = false;
    var apply = function () {
      el.classList.toggle('is-elevated', window.scrollY > 8);
      ticking = false;
    };

    window.addEventListener(
      'scroll',
      function () {
        if (ticking) return;
        ticking = true;
        window.requestAnimationFrame(apply);
      },
      { passive: true }
    );
    apply();
  })();

  /* ---------------------------------------------------------- mobile drawer */
  (function drawer() {
    var toggle = $('[data-menu-toggle]');
    var panel = $('[data-drawer]');
    var scrim = $('[data-scrim]');
    if (!toggle || !panel || !scrim) return;

    var open = false;

    function setOpen(next) {
      if (next === open) return;
      open = next;
      toggle.setAttribute('aria-expanded', String(open));
      toggle.setAttribute('aria-label', open ? 'Close navigation menu' : 'Open navigation menu');
      document.body.classList.toggle('is-locked', open);

      if (open) {
        panel.hidden = false;
        scrim.hidden = false;
        // Next frame, so the transition has a starting state to animate from.
        window.requestAnimationFrame(function () {
          panel.classList.add('is-open');
          scrim.classList.add('is-open');
        });
        return;
      }

      panel.classList.remove('is-open');
      scrim.classList.remove('is-open');
      window.setTimeout(
        function () {
          if (open) return;
          panel.hidden = true;
          scrim.hidden = true;
        },
        reduceMotion ? 0 : 220
      );
    }

    toggle.addEventListener('click', function () {
      setOpen(!open);
    });
    scrim.addEventListener('click', function () {
      setOpen(false);
    });
    $$('[data-drawer-link]', panel).forEach(function (link) {
      link.addEventListener('click', function () {
        setOpen(false);
      });
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && open) {
        setOpen(false);
        toggle.focus();
      }
    });
    window.addEventListener('resize', function () {
      if (window.innerWidth > 1024) setOpen(false);
    });
  })();

  /* ------------------------------------------------------------- scrollspy */
  (function scrollspy() {
    var links = $$('[data-nav-link]');
    if (!links.length || !('IntersectionObserver' in window)) return;

    var sections = links
      .map(function (link) {
        var id = link.getAttribute('href');
        return id && id.charAt(0) === '#' ? document.querySelector(id) : null;
      })
      .filter(Boolean);
    if (!sections.length) return;

    var visible = new Map();

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          visible.set(entry.target.id, entry.isIntersecting ? entry.intersectionRatio : 0);
        });

        var best = '';
        var bestRatio = 0;
        visible.forEach(function (ratio, id) {
          if (ratio > bestRatio) {
            bestRatio = ratio;
            best = id;
          }
        });

        links.forEach(function (link) {
          link.classList.toggle('is-active', link.getAttribute('href') === '#' + best);
        });
      },
      { rootMargin: '-45% 0px -45% 0px', threshold: [0, 0.25, 0.5, 1] }
    );

    sections.forEach(function (section) {
      observer.observe(section);
    });
  })();

  /* ---------------------------------------------------------- scroll reveal */
  (function reveal() {
    var targets = $$('[data-reveal]');
    if (!targets.length) return;

    if (reduceMotion || !('IntersectionObserver' in window)) {
      targets.forEach(function (target) {
        target.classList.add('is-visible');
      });
      return;
    }

    // Cascade the children of grids and the stepper.
    targets.forEach(function (target) {
      if (!target.classList.contains('grid') && !target.classList.contains('stepper')) return;
      Array.prototype.forEach.call(target.children, function (child, index) {
        child.style.setProperty('--reveal-delay', Math.min(index, 8) * 60 + 'ms');
      });
    });

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        });
      },
      { rootMargin: '0px 0px -10% 0px', threshold: 0.08 }
    );

    targets.forEach(function (target) {
      observer.observe(target);
    });
  })();

  /* ------------------------------------------------------------- accordion */
  (function accordion() {
    $$('[data-accordion]').forEach(function (group) {
      var items = $$('details', group);
      items.forEach(function (item) {
        item.addEventListener('toggle', function () {
          if (!item.open) return;
          item.classList.add('is-animating');
          window.setTimeout(function () {
            item.classList.remove('is-animating');
          }, 320);
          // One panel open at a time keeps the list scannable.
          items.forEach(function (other) {
            if (other !== item) other.open = false;
          });
        });
      });
    });
  })();

  /* ---------------------------------------------------------- booking form */
  (function booking() {
    var form = $('[data-booking-form]');
    if (!form) return;

    var status = $('[data-booking-status]', form);
    var whatsappBtn = $('[data-booking-whatsapp]', form);
    var fields = {
      pickup: $('#pickup', form),
      drop: $('#drop', form),
      date: $('#date', form),
      time: $('#time', form),
      vehicle: $('#vehicle', form),
      mobile: $('#mobile', form),
    };

    // Past dates are never a valid booking.
    if (fields.date) fields.date.min = new Date().toISOString().slice(0, 10);

    var RULES = {
      pickup: function (value) {
        return value.length >= 2 ? '' : 'Enter a pickup location.';
      },
      drop: function (value) {
        return value.length >= 2 ? '' : 'Enter a drop location.';
      },
      date: function (value) {
        return value ? '' : 'Choose a travel date.';
      },
      time: function (value) {
        return value ? '' : 'Choose a pickup time.';
      },
      mobile: function (value) {
        var digits = value.replace(/\D/g, '');
        if (!digits) return 'Enter a mobile number.';
        // 10-digit Indian mobile, optionally with a 91 country code.
        return /^(91)?[6-9]\d{9}$/.test(digits) ? '' : 'Enter a valid 10-digit mobile number.';
      },
    };

    function setError(name, message) {
      var input = fields[name];
      if (!input) return;
      var wrapper = input.closest('.field');
      var slot = form.querySelector('[data-error-for="' + name + '"]');
      if (wrapper) wrapper.classList.toggle('has-error', Boolean(message));
      if (input.setAttribute) input.setAttribute('aria-invalid', message ? 'true' : 'false');
      if (slot) {
        slot.textContent = message;
        slot.hidden = !message;
      }
    }

    function validate() {
      var firstInvalid = null;
      Object.keys(RULES).forEach(function (name) {
        var input = fields[name];
        if (!input) return;
        var message = RULES[name](input.value.trim());
        setError(name, message);
        if (message && !firstInvalid) firstInvalid = input;
      });
      return firstInvalid;
    }

    // Clear a field's error as soon as it becomes valid again.
    Object.keys(RULES).forEach(function (name) {
      var input = fields[name];
      if (!input) return;
      input.addEventListener('input', function () {
        if (input.closest('.field').classList.contains('has-error')) {
          setError(name, RULES[name](input.value.trim()));
        }
      });
      input.addEventListener('blur', function () {
        if (input.value.trim()) setError(name, RULES[name](input.value.trim()));
      });
    });

    function tripMessage() {
      var value = function (key) {
        return fields[key] && fields[key].value ? fields[key].value.trim() : '';
      };
      var lines = [
        'Hi Sagar Tours and Travels, I would like to book a taxi.',
        '',
        'Pickup: ' + (value('pickup') || '—'),
        'Drop: ' + (value('drop') || '—'),
        'Date: ' + (value('date') || '—'),
        'Time: ' + (value('time') || '—'),
        'Vehicle: ' + (value('vehicle') || 'Any — please suggest one'),
        'Mobile: ' + (value('mobile') || '—'),
      ];
      return lines.join('\n');
    }

    function whatsappUrl() {
      var base = whatsappBtn ? whatsappBtn.getAttribute('data-wa-base') : '';
      if (!base) {
        // Falls back to the number on the mobile action bar / header.
        var anchor = document.querySelector('a[href^="https://wa.me/"]');
        base = anchor ? anchor.getAttribute('href').split('?')[0] : '';
      }
      return base ? base + '?text=' + encodeURIComponent(tripMessage()) : '';
    }

    function say(message, tone) {
      if (!status) return;
      status.textContent = message;
      status.className = 'booking-form__status' + (tone ? ' is-' + tone : '');
    }

    if (whatsappBtn) {
      whatsappBtn.addEventListener('click', function (event) {
        var url = whatsappUrl();
        if (!url) return;
        event.preventDefault();
        window.open(url, '_blank', 'noopener');
        say('Your trip details were copied into WhatsApp. Send the message to confirm.', 'success');
      });
    }

    form.addEventListener('submit', function (event) {
      event.preventDefault();
      var invalid = validate();
      if (invalid) {
        say('Please complete the highlighted fields.', 'error');
        invalid.focus();
        return;
      }

      /*
       * There is no booking backend yet. Set `window.SAGAR_BOOKING_ENDPOINT` to
       * a URL that accepts a JSON POST and the form will submit to it instead
       * of handing off to WhatsApp. See README.md.
       */
      var endpoint = window.SAGAR_BOOKING_ENDPOINT;
      if (endpoint) {
        say('Sending your request…');
        var payload = {};
        Object.keys(fields).forEach(function (name) {
          if (fields[name]) payload[name] = fields[name].value;
        });
        window
          .fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          })
          .then(function (response) {
            if (!response.ok) throw new Error('Request failed');
            form.reset();
            say('Thank you. We have your request and will call you back with a fare.', 'success');
          })
          .catch(function () {
            say('Something went wrong. Please call or message us on WhatsApp instead.', 'error');
          });
        return;
      }

      var url = whatsappUrl();
      if (url) {
        window.open(url, '_blank', 'noopener');
        say('Your trip details were copied into WhatsApp. Send the message to get your fare.', 'success');
      } else {
        say('Please call us to get your fare.', 'error');
      }
    });

    /* Card "Book Now" links prefill the form, then scroll to it. */
    var PREFILL = {
      'data-prefill-pickup': 'pickup',
      'data-prefill-drop': 'drop',
      'data-prefill-vehicle': 'vehicle',
    };

    $$('[data-prefill-pickup], [data-prefill-drop], [data-prefill-vehicle], [data-prefill-service]').forEach(
      function (link) {
        link.addEventListener('click', function () {
          Object.keys(PREFILL).forEach(function (attribute) {
            var value = link.getAttribute(attribute);
            var input = fields[PREFILL[attribute]];
            if (!value || !input) return;

            if (input.tagName === 'SELECT') {
              var match = Array.prototype.find.call(input.options, function (option) {
                return option.value === value;
              });
              if (match) input.value = value;
            } else {
              input.value = value;
            }
            input.dispatchEvent(new Event('input', { bubbles: true }));
          });

          var service = link.getAttribute('data-prefill-service');
          if (service) say('Booking ' + service + '. Fill in your trip details below.');
        });
      }
    );
  })();
})();

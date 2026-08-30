import { NumerologyError } from '@numerology/core';
import { ApiError } from '../api/client';
import { toUserMessage } from '../lib/run';

describe('toUserMessage', () => {
  it('never leaks a technical message to the user', () => {
    const message = toUserMessage(new Error('ECONNREFUSED 127.0.0.1:4000 at Object.<anonymous>'), 'en');
    expect(message).toBe('Something went wrong. Please try again.');
  });

  it('explains a network failure', () => {
    const message = toUserMessage(new ApiError('NETWORK', 'boom'), 'en');
    expect(message).toBe('Unable to connect. Please check your internet connection.');
  });

  it('maps engine errors onto friendly text', () => {
    expect(toUserMessage(new NumerologyError('INVALID_DATE', 'x'), 'en')).toBe('Please enter a valid Date of Birth.');
    expect(toUserMessage(new NumerologyError('FUTURE_DATE', 'x'), 'en')).toBe('Please enter a valid Date of Birth.');
    expect(toUserMessage(new NumerologyError('NO_DIGITS', 'x'), 'en')).toBe('Please enter a valid number.');
    expect(toUserMessage(new NumerologyError('EMPTY_NAME', 'x'), 'en')).toBe('Please enter a valid name.');
  });

  it('answers in the user language', () => {
    expect(toUserMessage(new ApiError('NETWORK', 'boom'), 'hi')).toContain('इंटरनेट');
    expect(toUserMessage(new ApiError('NETWORK', 'boom'), 'mr')).toContain('इंटरनेट');
  });

  it('passes through a validation message from the API', () => {
    const message = toUserMessage(new ApiError('VALIDATION_ERROR', 'Please enter a valid date of birth.', 422), 'en');
    expect(message).toBe('Please enter a valid date of birth.');
  });
});

/** Error codes the API maps onto user facing, localised messages. */
export type NumerologyErrorCode =
  | 'INVALID_DATE'
  | 'FUTURE_DATE'
  | 'DATE_TOO_OLD'
  | 'EMPTY_NUMBER'
  | 'NO_DIGITS'
  | 'NUMBER_TOO_LONG'
  | 'EMPTY_NAME'
  | 'NAME_TOO_LONG'
  | 'NO_MAPPABLE_LETTERS';

export class NumerologyError extends Error {
  readonly code: NumerologyErrorCode;

  constructor(code: NumerologyErrorCode, message: string) {
    super(message);
    this.name = 'NumerologyError';
    this.code = code;
  }
}

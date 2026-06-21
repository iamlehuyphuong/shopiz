/* eslint-disable max-classes-per-file */
export class DuplicateContactException extends Error {
  constructor(data, existingContactId = null) {
    super('DUPLICATE_CONTACT');
    this.data = data;
    this.existingContactId = existingContactId;
    this.name = 'DuplicateContactException';
  }
}
export class ExceptionWithMessage extends Error {
  constructor(data) {
    super('ERROR_WITH_MESSAGE');
    this.data = data;
    this.name = 'ExceptionWithMessage';
  }
}

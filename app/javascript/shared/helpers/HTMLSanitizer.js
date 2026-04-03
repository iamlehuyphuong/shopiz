export const escapeHtml = (unsafe = '') => {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

export const afterSanitizeAttributes = currentNode => {
  if ('target' in currentNode) {
    currentNode.setAttribute('target', '_blank');
  }
};

export const domPurifyConfig = {
  ALLOWED_ATTR: [
    'style',
    'class',
    'id',
    'target',
    'href',
    'src',
    'width',
    'height',
    'data-type',
    'data-value',
    'data-copy-text',
    'rel',
  ],
  hooks: {
    afterSanitizeAttributes,
  },
};

import {
  INBOX_TYPES,
  getInboxClassByType,
  getInboxIconByType,
  getInboxWarningIconClass,
} from '../inbox';

describe('#Inbox Helpers', () => {
  describe('getInboxClassByType', () => {
    it('should return correct class for web widget', () => {
      expect(getInboxClassByType('Channel::WebWidget')).toEqual(
        'globe-desktop'
      );
    });
    it('should return correct class for fb page', () => {
      expect(getInboxClassByType('Channel::FacebookPage')).toEqual(
        'brand-facebook'
      );
    });
    it('should return correct class for Api', () => {
      expect(getInboxClassByType('Channel::Api')).toEqual('cloud');
    });
    it('should return correct class for TikTok', () => {
      expect(getInboxClassByType(INBOX_TYPES.TIKTOK)).toEqual('brand-tiktok');
    });
  });

  describe('getInboxIconByType', () => {
    describe('fill variant (default)', () => {
      it('returns correct icon for web widget', () => {
        expect(getInboxIconByType(INBOX_TYPES.WEB)).toBe('i-ri-global-fill');
      });

      it('returns correct icon for Facebook', () => {
        expect(getInboxIconByType(INBOX_TYPES.FB)).toBe('i-ri-messenger-fill');
      });

      it('returns correct icon for WhatsApp', () => {
        expect(getInboxIconByType(INBOX_TYPES.WHATSAPP)).toBe(
          'i-ri-whatsapp-fill'
        );
      });

      it('returns correct icon for API', () => {
        expect(getInboxIconByType(INBOX_TYPES.API)).toBe('i-ri-cloudy-fill');
      });

      it('returns correct icon for Telegram', () => {
        expect(getInboxIconByType(INBOX_TYPES.TELEGRAM)).toBe(
          'i-ri-telegram-fill'
        );
      });

      it('returns correct icon for TikTok', () => {
        expect(getInboxIconByType(INBOX_TYPES.TIKTOK)).toBe('i-woot-tiktok');
      });

      it('returns default icon for unknown type', () => {
        expect(getInboxIconByType('UNKNOWN_TYPE')).toBe('i-ri-chat-1-fill');
      });

      it('returns default icon for undefined type', () => {
        expect(getInboxIconByType(undefined)).toBe('i-ri-chat-1-fill');
      });
    });

    describe('line variant', () => {
      it('returns correct line icon for web widget', () => {
        expect(getInboxIconByType(INBOX_TYPES.WEB, null, 'line')).toBe(
          'i-woot-website'
        );
      });

      it('returns correct line icon for Facebook', () => {
        expect(getInboxIconByType(INBOX_TYPES.FB, null, 'line')).toBe(
          'i-woot-messenger'
        );
      });

      it('returns correct line icon for TikTok', () => {
        expect(getInboxIconByType(INBOX_TYPES.TIKTOK, null, 'line')).toBe(
          'i-woot-tiktok'
        );
      });

      it('returns correct line icon for unknown type', () => {
        expect(getInboxIconByType('UNKNOWN_TYPE', null, 'line')).toBe(
          'i-ri-chat-1-line'
        );
      });
    });

  });
});

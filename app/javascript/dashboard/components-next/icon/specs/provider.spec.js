import { useChannelIcon } from '../provider';

describe('useChannelIcon', () => {
  it('returns correct icon for API channel', () => {
    const inbox = { channel_type: 'Channel::Api' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-api');
  });

  it('returns correct icon for Facebook channel', () => {
    const inbox = { channel_type: 'Channel::FacebookPage' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-messenger');
  });

  it('returns correct icon for WhatsApp channel', () => {
    const inbox = { channel_type: 'Channel::Whatsapp' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-whatsapp');
  });

  it('returns correct icon for WebWidget channel', () => {
    const inbox = { channel_type: 'Channel::WebWidget' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-website');
  });

  it('returns correct icon for Instagram channel', () => {
    const inbox = { channel_type: 'Channel::Instagram' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-instagram');
  });

  it('returns correct icon for TikTok channel', () => {
    const inbox = { channel_type: 'Channel::Tiktok' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-woot-tiktok');
  });

  it('returns default icon for unknown channel type', () => {
    const inbox = { channel_type: 'Channel::Unknown' };
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-global-fill');
  });

  it('returns default icon when channel type is undefined', () => {
    const inbox = {};
    const { value: icon } = useChannelIcon(inbox);
    expect(icon).toBe('i-ri-global-fill');
  });
});

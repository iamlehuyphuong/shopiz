<script>
import { defineComponent, h } from 'vue';
import Facebook from './channels/Facebook.vue';
import Zalo from './channels/Zalo.vue';
import ZaloPersonal from './channels/ZaloPersonal.vue';
import Website from './channels/Website.vue';
import Twitter from './channels/Twitter.vue';
import Api from './channels/Api.vue';
import Sms from './channels/Sms.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Line from './channels/Line.vue';
import Telegram from './channels/Telegram.vue';
import Instagram from './channels/Instagram.vue';
import Tiktok from './channels/Tiktok.vue';
import Voice from './channels/Voice.vue';
import TikTokShop from './channels/TikTokShop.vue';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  twitter: Twitter,
  api: Api,
  sms: Sms,
  whatsapp: Whatsapp,
  line: Line,
  telegram: Telegram,
  instagram: Instagram,
  tiktok: Tiktok,
  voice: Voice,
  zalo: Zalo,
  zalopersonal: ZaloPersonal,
  tiktok_shop: TikTokShop,
};

export default defineComponent({
  name: 'NewChannelView',
  props: {
    channelName: {
      type: String,
      required: true,
    },
  },
  render() {
    const ChannelComponent = channelViewList[this.channelName];
    return ChannelComponent ? h(ChannelComponent) : null;
  },
});
</script>

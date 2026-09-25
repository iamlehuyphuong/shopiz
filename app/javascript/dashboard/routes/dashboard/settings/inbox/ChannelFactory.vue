<script>
import { defineComponent, h } from 'vue';
import Facebook from './channels/Facebook.vue';
import Zalo from './channels/Zalo.vue';
import ZaloPersonal from './channels/ZaloPersonal.vue';
import Website from './channels/Website.vue';
import Api from './channels/Api.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Telegram from './channels/Telegram.vue';
import Instagram from './channels/Instagram.vue';
import Tiktok from './channels/Tiktok.vue';
import TikTokShop from './channels/TikTokShop.vue';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  api: Api,
  whatsapp: Whatsapp,
  telegram: Telegram,
  instagram: Instagram,
  tiktok: Tiktok,
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

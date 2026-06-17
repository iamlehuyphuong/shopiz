<script>
import { mapGetters } from 'vuex';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  name: 'NetworkIllustration',
  components: {
    Icon,
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    allPlatforms() {
      return [...this.communicationPlatforms, ...this.dataPlatforms];
    },
    satellitePositions() {
      // Distances to create an organic inner/outer ring effect
      const distances = [340, 220, 360, 240, 350, 230, 340, 220, 360, 240];
      const totalItems = this.allPlatforms.length;

      return this.allPlatforms.map((platform, index) => {
        const angleDeg = index * (360 / totalItems);
        // Shift by 15 degrees so they aren't perfectly aligned to axes
        const angleRad = ((angleDeg - 15) * Math.PI) / 180;
        const distance = distances[index % distances.length];
        // Center of the 1100x700 container is (550, 350)
        return {
          x: 550 + Math.cos(angleRad) * distance,
          y: 350 + Math.sin(angleRad) * distance,
        };
      });
    },
  },
  data() {
    return {
      communicationPlatforms: [
        {
          name: 'Messenger',
          icon: 'i-woot-messenger',
          color: 'text-[#1877F2]',
          bg: 'bg-[#EAF3FF]',
        },
        {
          name: 'Whatsapp',
          icon: 'i-woot-whatsapp',
          color: 'text-[#25D366]',
          bg: 'bg-[#E8F9EE]',
        },
        {
          name: 'Instagram',
          icon: 'i-woot-instagram',
          color: 'text-[#E4405F]',
          bg: 'bg-[#FCECF0]',
        },
        {
          name: 'Tiktok',
          icon: 'i-woot-tiktok',
          color: 'text-gray-900',
          bg: 'bg-[#F3F4F6]',
        },
        {
          name: 'Zalo',
          icon: 'i-woot-zalo-oa',
          color: 'text-[#0068FF]',
          bg: 'bg-[#EAF3FF]',
        },
        {
          name: 'Telegram',
          icon: 'i-woot-telegram',
          color: 'text-[#0088CC]',
          bg: 'bg-[#E5F5FC]',
        },
        {
          name: 'Livechat',
          icon: 'i-lucide-message-circle',
          color: 'text-[#FF6A39]',
          bg: 'bg-[#FFF0EB]',
        },
      ],
      dataPlatforms: [
        {
          name: 'Shopify',
          image: '/dashboard/images/integrations/shopify.png',
          bg: 'bg-[#F2F8E8]',
        },
        {
          name: 'WooCommerce',
          image: '/dashboard/images/integrations/woocommerce.png',
          bg: 'bg-[#F2EBF0]',
        },
        {
          name: 'Calendly',
          image: '/dashboard/images/integrations/calendly.png',
          bg: 'bg-[#E5F0FC]',
        },
      ],
    };
  },
};
</script>

<template>
  <div
    class="relative w-full h-full bg-[#FAFAFA] flex items-center justify-center overflow-hidden font-sans"
  >
    <!-- Grid Background -->
    <div
      class="absolute inset-0"
      style="
        background-image: linear-gradient(#e5e7eb 1px, transparent 1px),
          linear-gradient(90deg, #e5e7eb 1px, transparent 1px);
        background-size: 30px 30px;
        opacity: 0.6;
      "
    />

    <div class="absolute inset-0 flex items-center justify-center">
      <div
        class="relative w-[1100px] h-[900px] scale-[0.4] sm:scale-[0.5] md:scale-[0.55] lg:scale-[0.55] xl:scale-[0.65] 2xl:scale-75 flex flex-col items-center justify-center z-10 transition-transform duration-500"
      >
        <!-- Diagram Section -->
        <div
          class="relative w-[1100px] h-[700px] flex items-center justify-center mb-12"
        >
          <!-- Background Connecting Lines -->
          <svg
            class="absolute inset-0 w-full h-full z-0"
            viewBox="0 0 1100 700"
            xmlns="http://www.w3.org/2000/svg"
          >
            <!-- Concentric Orbit Rings -->
            <circle
              cx="550"
              cy="350"
              r="230"
              fill="none"
              stroke="#FFD8CC"
              stroke-width="1.5"
              stroke-dasharray="6 6"
              opacity="0.6"
            />
            <circle
              cx="550"
              cy="350"
              r="350"
              fill="none"
              stroke="#FFD8CC"
              stroke-width="1.5"
              stroke-dasharray="6 6"
              opacity="0.4"
            />

            <!-- Spokes connecting center to nodes -->
            <g stroke="#FFD8CC" stroke-width="1.5" opacity="0.8">
              <line
                v-for="(pos, index) in satellitePositions"
                :key="'spoke-' + index"
                x1="550"
                y1="350"
                :x2="pos.x"
                :y2="pos.y"
              />
            </g>

            <!-- Glowing dots on the rings -->
            <circle cx="550" cy="120" r="4" fill="#FF6A39" opacity="0.8" />
            <circle cx="550" cy="580" r="4" fill="#FF6A39" opacity="0.8" />
            <circle cx="320" cy="350" r="5" fill="#FF9B7D" opacity="0.9" />
            <circle cx="780" cy="350" r="3" fill="#FFC5B2" opacity="0.9" />
            <circle cx="750" cy="180" r="5" fill="#FF9B7D" opacity="0.9" />
            <circle cx="350" cy="520" r="4" fill="#FF6A39" opacity="0.7" />
          </svg>

          <!-- Center Block: SHOPIZ -->
          <div
            class="absolute left-[50%] top-[350px] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center bg-white rounded-full size-[180px] shadow-[0_30px_60px_rgba(255,106,57,0.2)] border-[6px] border-white z-20"
          >
            <div
              class="absolute inset-0 rounded-full shadow-[0_0_80px_rgba(255,106,57,0.3)] mix-blend-multiply"
            />
            <img
              :src="globalConfig.logoThumbnail"
              alt="Shopiz"
              class="h-24 w-auto relative z-10 drop-shadow-md"
            />
          </div>

          <!-- Orbiting Satellites -->
          <div
            v-for="(item, index) in allPlatforms"
            :key="'sat-' + index"
            class="absolute flex flex-col items-center justify-center p-3 rounded-[24px] shadow-[0_15px_30px_rgba(0,0,0,0.06)] hover:scale-110 hover:shadow-[0_20px_40px_rgba(255,106,57,0.15)] transition-all duration-300 z-10 bg-white border border-gray-100 cursor-pointer"
            :style="{
              left: satellitePositions[index].x + 'px',
              top: satellitePositions[index].y + 'px',
              transform: 'translate(-50%, -50%)',
              width: '96px',
              height: '96px',
            }"
          >
            <div
              class="flex items-center justify-center size-[48px] rounded-[16px] mb-2"
              :class="item.bg"
            >
              <Icon
                v-if="item.icon"
                :icon="item.icon"
                class="size-6"
                :class="item.color"
              />
              <img
                v-else-if="item.image"
                :src="item.image"
                :alt="item.name"
                class="size-7 object-contain"
              />
            </div>
            <span
              class="text-[11px] font-bold text-gray-700 truncate w-full text-center tracking-wide"
              >{{ item.name }}</span>
          </div>
        </div>

        <!-- Title Section -->
        <div class="flex flex-col items-center text-center mt-16 w-[1000px]">
          <h2
            class="text-[46px] font-extrabold text-gray-900 mb-2 tracking-tight leading-tight"
          >
            {{ $t('LOGIN.ILLUSTRATION.TITLE_GRAY') }} <br />
            <span class="text-[#FF6A39]">{{
              $t('LOGIN.ILLUSTRATION.TITLE_ORANGE')
            }}</span>
          </h2>
        </div>
      </div>
    </div>
  </div>
</template>

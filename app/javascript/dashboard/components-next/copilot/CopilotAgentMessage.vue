<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const currentUser = useMapGetter('getCurrentUser');

const currentUserName = computed(() => currentUser.value?.name);
const currentUserAvatar = computed(() => currentUser.value?.avatar_url);
</script>

<template>
  <div class="space-y-1 text-n-slate-12">
    <div class="flex items-center gap-2 font-medium">
      <Avatar
        :name="currentUserName || $t('CAPTAIN.COPILOT.YOU')"
        :src="currentUserAvatar"
        :size="20"
        rounded-full
        icon-name="i-lucide-user"
      />
      <span>{{ $t('CAPTAIN.COPILOT.YOU') }}</span>
    </div>
    <div class="break-words">
      {{ message.content }}
    </div>
  </div>
</template>

<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import LanguageDropdown from 'dashboard/components-next/LanguageDropdown/LanguageDropdown.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AddTemplate from './AddTemplate.vue';
import ChannelOverviewCard from './components/ChannelOverviewCard.vue';
import UnifiedTemplateRow from './components/UnifiedTemplateRow.vue';
import ZaloMessageTemplatesAPI from 'dashboard/api/zaloMessageTemplates';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const showAddPopup = ref(false);
const isSyncing = ref(false);

// Filter states
const selectedStatus = ref('');
const selectedLanguage = ref('');
const selectedChannelType = ref('');

// Dropdown states
const isStatusDropdownOpen = ref(false);
const isChannelDropdownOpen = ref(false);

// Zalo templates local state
const zaloTemplates = ref([]);
const isLoadingZalo = ref(false);

// Store-based computed properties
const waTemplates = computed(
  () => store.getters['messageTemplates/getTemplates']
);
const uiFlags = computed(() => store.getters['messageTemplates/getUIFlags']);
const isLoadingWA = computed(() => uiFlags.value.isFetching);
const isDeleting = computed(() => uiFlags.value.isDeleting);

const allInboxes = useMapGetter('inboxes/getInboxes');
const accountId = useMapGetter('getCurrentAccountId');

// Channel-specific inboxes
const whatsappInboxes = computed(() =>
  allInboxes.value.filter(inbox => inbox.channel_type === 'Channel::Whatsapp')
);

const zaloOaInboxes = computed(() =>
  allInboxes.value.filter(inbox => inbox.channel_type === 'Channel::ZaloOa')
);

const tiktokShopInboxes = computed(() =>
  allInboxes.value.filter(inbox => inbox.channel_type === 'Channel::TiktokShop')
);

// Normalize WhatsApp templates
const normalizedWATemplates = computed(() =>
  waTemplates.value
    .filter(tpl => !tpl.channel_type || tpl.channel_type === 'Channel::Whatsapp')
    .map(tpl => ({
      id: `wa-${tpl.id}`,
      originalId: tpl.id,
      name: tpl.name,
      source: 'whatsapp',
      channelType: 'Channel::Whatsapp',
      inboxId: tpl.inbox_id,
      inboxName: whatsappInboxes.value.find(i => i.id === tpl.inbox_id)?.name || '',
      category: tpl.category,
      status: tpl.status,
      normalizedStatus: tpl.status,
      language: tpl.language,
      raw: tpl,
    }))
);

// Normalize TikTok Shop templates
const normalizedTiktokShopTemplates = computed(() =>
  waTemplates.value
    .filter(tpl => tpl.channel_type === 'Channel::TiktokShop')
    .map(tpl => ({
      id: `ttshop-${tpl.id}`,
      originalId: tpl.id,
      name: tpl.name,
      source: 'tiktok_shop',
      channelType: 'Channel::TiktokShop',
      inboxId: tpl.inbox_id,
      inboxName: tiktokShopInboxes.value.find(i => i.id === tpl.inbox_id)?.name || '',
      category: tpl.category,
      status: tpl.status,
      normalizedStatus: tpl.status,
      language: tpl.language,
      raw: tpl,
    }))
);

// Normalize Zalo templates
const normalizedZaloTemplates = computed(() =>
  zaloTemplates.value.map(tpl => {
    const inbox = zaloOaInboxes.value.find(
      i => i.channel_id === tpl.channel_id
    );
    return {
      id: `zalo-${tpl.id}`,
      originalId: tpl.id,
      name: tpl.template_name,
      source: 'zalo',
      channelType: 'Channel::ZaloOa',
      inboxId: inbox?.id,
      inboxName: inbox?.name || '',
      category: tpl.template_type,
      status: tpl.status,
      normalizedStatus: tpl.status,
      language: tpl.language || 'vi',
      raw: tpl,
    };
  })
);

// All templates merged
const allTemplates = computed(() => [
  ...normalizedWATemplates.value,
  ...normalizedZaloTemplates.value,
  ...normalizedTiktokShopTemplates.value,
]);

const isLoading = computed(() => isLoadingWA.value || isLoadingZalo.value);

// ── Channel Overview Data ──
const whatsappStatusGroups = computed(() => {
  const templates = normalizedWATemplates.value;
  return [
    {
      key: 'approved',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.APPROVED'),
      count: templates.filter(tp => tp.status === 'approved').length,
      barColor: 'bg-n-teal-9',
      textColor: 'text-n-teal-11',
    },
    {
      key: 'pending',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.PENDING'),
      count: templates.filter(tp => tp.status === 'pending').length,
      barColor: 'bg-n-amber-9',
      textColor: 'text-n-amber-11',
    },
    {
      key: 'rejected',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.REJECTED'),
      count: templates.filter(tp => tp.status === 'rejected').length,
      barColor: 'bg-n-ruby-9',
      textColor: 'text-n-ruby-11',
    },
  ];
});

const zaloStatusGroups = computed(() => {
  const templates = normalizedZaloTemplates.value;
  return [
    {
      key: 'active',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.ACTIVE'),
      count: templates.filter(tp => tp.status === 'active').length,
      barColor: 'bg-n-teal-9',
      textColor: 'text-n-teal-11',
    },
    {
      key: 'draft',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.DRAFT'),
      count: templates.filter(tp => tp.status === 'draft').length,
      barColor: 'bg-n-amber-9',
      textColor: 'text-n-amber-11',
    },
    {
      key: 'disabled',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.DISABLED'),
      count: templates.filter(tp => tp.status === 'disabled').length,
      barColor: 'bg-n-ruby-9',
      textColor: 'text-n-ruby-11',
    },
  ];
});

const tiktokShopStatusGroups = computed(() => {
  const templates = normalizedTiktokShopTemplates.value;
  return [
    {
      key: 'approved',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.APPROVED'),
      count: templates.filter(tp => tp.status === 'approved' || tp.status === 'active').length,
      barColor: 'bg-n-teal-9',
      textColor: 'text-n-teal-11',
    },
    {
      key: 'pending',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.PENDING'),
      count: templates.filter(tp => tp.status === 'pending').length,
      barColor: 'bg-n-amber-9',
      textColor: 'text-n-amber-11',
    },
    {
      key: 'rejected',
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.REJECTED'),
      count: templates.filter(tp => tp.status === 'rejected' || tp.status === 'disabled').length,
      barColor: 'bg-n-ruby-9',
      textColor: 'text-n-ruby-11',
    },
  ];
});

// ── Filter Options ──
const statusMenuItems = computed(() => {
  const base = [
    {
      action: 'statusSelect',
      value: '',
      label: t('SETTINGS.TEMPLATES.FILTERS.ALL_STATUSES'),
      isSelected: selectedStatus.value === '',
    },
  ];

  // Show relevant statuses based on selected channel
  if (
    !selectedChannelType.value ||
    selectedChannelType.value === 'Channel::Whatsapp'
  ) {
    base.push(
      {
        action: 'statusSelect',
        value: 'approved',
        label: t('SETTINGS.TEMPLATES.FILTERS.APPROVED'),
        isSelected: selectedStatus.value === 'approved',
      },
      {
        action: 'statusSelect',
        value: 'pending',
        label: t('SETTINGS.TEMPLATES.FILTERS.PENDING'),
        isSelected: selectedStatus.value === 'pending',
      },
      {
        action: 'statusSelect',
        value: 'rejected',
        label: t('SETTINGS.TEMPLATES.FILTERS.REJECTED'),
        isSelected: selectedStatus.value === 'rejected',
      }
    );
  }

  if (
    !selectedChannelType.value ||
    selectedChannelType.value === 'Channel::ZaloOa'
  ) {
    base.push(
      {
        action: 'statusSelect',
        value: 'active',
        label: t('SETTINGS.TEMPLATES.FILTERS.ACTIVE'),
        isSelected: selectedStatus.value === 'active',
      },
      {
        action: 'statusSelect',
        value: 'draft',
        label: t('SETTINGS.TEMPLATES.FILTERS.DRAFT'),
        isSelected: selectedStatus.value === 'draft',
      },
      {
        action: 'statusSelect',
        value: 'disabled',
        label: t('SETTINGS.TEMPLATES.FILTERS.DISABLED'),
        isSelected: selectedStatus.value === 'disabled',
      }
    );
  }

  return base;
});

const channelMenuItems = computed(() => [
  {
    action: 'channelSelect',
    value: '',
    label: t('SETTINGS.TEMPLATES.FILTERS.ALL_CHANNELS'),
    isSelected: selectedChannelType.value === '',
  },
  {
    action: 'channelSelect',
    value: 'Channel::Whatsapp',
    label: 'WhatsApp',
    isSelected: selectedChannelType.value === 'Channel::Whatsapp',
  },
  {
    action: 'channelSelect',
    value: 'Channel::ZaloOa',
    label: 'Zalo OA',
    isSelected: selectedChannelType.value === 'Channel::ZaloOa',
  },
  {
    action: 'channelSelect',
    value: 'Channel::TiktokShop',
    label: 'TikTok Shop',
    isSelected: selectedChannelType.value === 'Channel::TiktokShop',
  },
]);

const selectedStatusLabel = computed(() => {
  const selected = statusMenuItems.value.find(
    item => item.value === selectedStatus.value
  );
  return selected
    ? selected.label
    : t('SETTINGS.TEMPLATES.FILTERS.ALL_STATUSES');
});

const selectedChannelLabel = computed(() => {
  const selected = channelMenuItems.value.find(
    item => item.value === selectedChannelType.value
  );
  return selected
    ? selected.label
    : t('SETTINGS.TEMPLATES.FILTERS.ALL_CHANNELS');
});

// ── Filtered Templates ──
const filteredTemplates = computed(() => {
  return allTemplates.value.filter(template => {
    const matchesStatus =
      !selectedStatus.value ||
      template.normalizedStatus === selectedStatus.value;
    const matchesLanguage =
      !selectedLanguage.value ||
      template.language?.toLowerCase() === selectedLanguage.value.toLowerCase();
    const matchesChannel =
      !selectedChannelType.value ||
      template.channelType === selectedChannelType.value;

    return matchesStatus && matchesLanguage && matchesChannel;
  });
});

const hasActiveFilters = computed(() => {
  return (
    selectedStatus.value || selectedLanguage.value || selectedChannelType.value
  );
});

// ── Fetch Data ──
const fetchWhatsAppTemplates = async () => {
  try {
    await store.dispatch('messageTemplates/get');
  } catch {
    useAlert(t('SETTINGS.TEMPLATES.API.FETCH_ERROR'));
  }
};

const fetchZaloTemplates = async () => {
  if (zaloOaInboxes.value.length === 0) return;
  isLoadingZalo.value = true;
  try {
    const response = await ZaloMessageTemplatesAPI.getAll();
    zaloTemplates.value = response.data;
  } catch {
    // Silently fail — Zalo templates may not be configured
  } finally {
    isLoadingZalo.value = false;
  }
};

// ── Actions ──
const openAddPopup = () => {
  showAddPopup.value = true;
};

const hideAddPopup = () => {
  showAddPopup.value = false;
};

const handleStatusAction = ({ value }) => {
  selectedStatus.value = value;
  isStatusDropdownOpen.value = false;
};

const handleChannelAction = ({ value }) => {
  selectedChannelType.value = value;
  selectedStatus.value = '';
  isChannelDropdownOpen.value = false;
};

const handleChannelCardSelect = channelKey => {
  if (selectedChannelType.value === channelKey) {
    selectedChannelType.value = '';
  } else {
    selectedChannelType.value = channelKey;
  }
  selectedStatus.value = '';
};

const toggleStatusDropdown = () => {
  isStatusDropdownOpen.value = !isStatusDropdownOpen.value;
};

const toggleChannelDropdown = () => {
  isChannelDropdownOpen.value = !isChannelDropdownOpen.value;
};

const closeStatusDropdown = () => {
  isStatusDropdownOpen.value = false;
};

const closeChannelDropdown = () => {
  isChannelDropdownOpen.value = false;
};

const clearFilters = () => {
  selectedStatus.value = '';
  selectedLanguage.value = '';
  selectedChannelType.value = '';
};

const navigateToInbox = template => {
  if (!template.inboxId) return;
  const tabKey = template.source === 'zalo' ? 'message-templates' : '';
  const basePath = `/app/accounts/${accountId.value}/settings/inboxes/${template.inboxId}`;
  const path = tabKey ? `${basePath}/${tabKey}` : basePath;
  router.push(path);
};

// ── Delete ──
const showDeletePopup = ref(false);
const selectedTemplate = ref({});

const openDelete = template => {
  showDeletePopup.value = true;
  selectedTemplate.value = template;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedTemplate.value = {};
};

const confirmDeletion = async () => {
  try {
    if (selectedTemplate.value.source === 'whatsapp') {
      await store.dispatch(
        'messageTemplates/delete',
        selectedTemplate.value.originalId
      );
    } else if (selectedTemplate.value.source === 'zalo') {
      await ZaloMessageTemplatesAPI.delete(selectedTemplate.value.originalId);
      zaloTemplates.value = zaloTemplates.value.filter(
        tpl => tpl.id !== selectedTemplate.value.originalId
      );
    }
    useAlert(t('SETTINGS.TEMPLATES.DELETE.API.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('SETTINGS.TEMPLATES.DELETE.API.ERROR_MESSAGE'));
  } finally {
    closeDelete();
  }
};

const confirmDeleteTitle = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.TITLE', {
    templateName: selectedTemplate.value.name,
  })
);

const deleteConfirmText = computed(
  () =>
    `${t('SETTINGS.TEMPLATES.DELETE.CONFIRM.YES')} ${selectedTemplate.value.name}`
);

const deleteRejectText = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.NO')
);

const confirmPlaceHolderText = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.PLACE_HOLDER', {
    templateName: selectedTemplate.value.name,
  })
);

// ── Keyboard ──
const onKeydown = e => {
  if (showAddPopup.value && e.code === 'Escape') {
    hideAddPopup();
    e.stopPropagation();
  }
};

useEventListener(document, 'keydown', onKeydown);

// ── Sync ──
const syncAllTemplates = async () => {
  isSyncing.value = true;
  try {
    const inboxesToSync = [
      ...whatsappInboxes.value,
      ...zaloOaInboxes.value,
      ...tiktokShopInboxes.value,
    ];

    if (inboxesToSync.length === 0) {
      useAlert(t('SETTINGS.TEMPLATES.SYNC_ERROR', 'Không tìm thấy kênh nào hỗ trợ đồng bộ mẫu.'));
      return;
    }

    // Trigger sync for all relevant inboxes concurrently
    await Promise.allSettled(
      inboxesToSync.map(inbox => store.dispatch('inboxes/syncTemplates', inbox.id))
    );

    // Re-fetch templates
    await fetchWhatsAppTemplates();
    await fetchZaloTemplates();

    useAlert(t('SETTINGS.TEMPLATES.SYNC_SUCCESS', 'Đã gởi yêu cầu đồng bộ cấu trúc mẫu thành công.'));
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.SYNC_ERROR', 'Có lỗi khi đồng bộ mẫu.'));
  } finally {
    isSyncing.value = false;
  }
};

onMounted(() => {
  fetchWhatsAppTemplates();
  fetchZaloTemplates();
});
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-heading-1 text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.HEADER.TITLE') }}
        </h1>
        <p class="text-body-main text-n-slate-11 mt-1">
          {{ t('SETTINGS.TEMPLATES.HEADER.DESCRIPTION') }}
        </p>
      </div>
      <div class="relative flex items-center gap-2">
        <Button
          icon="i-lucide-refresh-cw"
          :label="'Đồng bộ mẫu'"
          :is-loading="isSyncing"
          color-scheme="secondary"
          @click="syncAllTemplates"
        />
        <Button
          icon="i-lucide-plus"
          blue
          :label="t('SETTINGS.TEMPLATES.ACTIONS.NEW_TEMPLATE')"
          @click="openAddPopup"
        />
        <!-- Add Template Popover -->
        <div v-if="showAddPopup" class="absolute right-0 top-full mt-2 z-50">
          <div
            class="bg-n-alpha-3 border border-n-strong rounded-xl shadow-sm backdrop-blur-[100px] w-[480px] max-h-[80vh] overflow-auto"
            @click.stop
          >
            <AddTemplate @close="hideAddPopup" />
          </div>
        </div>
      </div>
    </div>

    <!-- Channel Overview Cards -->
    <div class="grid grid-cols-1 lg:grid-cols-3 md:grid-cols-2 gap-4 mb-6">
      <ChannelOverviewCard
        channel-key="Channel::Whatsapp"
        channel-name="WhatsApp"
        channel-icon="i-ri-whatsapp-fill"
        icon-color="text-green-500"
        :inbox-count="whatsappInboxes.length"
        :templates="normalizedWATemplates"
        :status-groups="whatsappStatusGroups"
        :is-active="selectedChannelType === 'Channel::Whatsapp'"
        @select="handleChannelCardSelect"
      />
      <ChannelOverviewCard
        channel-key="Channel::ZaloOa"
        channel-name="Zalo OA"
        channel-icon="i-ri-zalo-oa-fill"
        icon-color="text-orange-500"
        :inbox-count="zaloOaInboxes.length"
        :templates="normalizedZaloTemplates"
        :status-groups="zaloStatusGroups"
        :is-active="selectedChannelType === 'Channel::ZaloOa'"
        @select="handleChannelCardSelect"
      />
      <ChannelOverviewCard
        channel-key="Channel::TiktokShop"
        channel-name="TikTok Shop"
        channel-icon="i-ri-tiktok-fill"
        icon-color="text-n-slate-12"
        :inbox-count="tiktokShopInboxes.length"
        :templates="normalizedTiktokShopTemplates"
        :status-groups="tiktokShopStatusGroups"
        :is-active="selectedChannelType === 'Channel::TiktokShop'"
        @select="handleChannelCardSelect"
      />
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-3 mb-5">
      <!-- Status Filter -->
      <div v-on-click-outside="closeStatusDropdown" class="relative w-44">
        <button
          type="button"
          class="flex items-center justify-between gap-2 h-9 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-0 focus-visible:ring-2 focus-visible:ring-n-orange-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
          @click="toggleStatusDropdown"
        >
          <span class="truncate">{{ selectedStatusLabel }}</span>
          <Icon
            icon="i-lucide-chevron-down"
            class="size-4 flex-shrink-0 transition-transform"
            :class="{ 'rotate-180': isStatusDropdownOpen }"
          />
        </button>
        <DropdownMenu
          v-if="isStatusDropdownOpen"
          :menu-items="statusMenuItems"
          class="absolute top-full mt-1 left-0 right-0 w-full z-50"
          @action="handleStatusAction"
        />
      </div>

      <!-- Channel Filter -->
      <div v-on-click-outside="closeChannelDropdown" class="relative w-44">
        <button
          type="button"
          class="flex items-center justify-between gap-2 h-9 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-0 focus-visible:ring-2 focus-visible:ring-n-orange-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
          @click="toggleChannelDropdown"
        >
          <span class="truncate">{{ selectedChannelLabel }}</span>
          <Icon
            icon="i-lucide-chevron-down"
            class="size-4 flex-shrink-0 transition-transform"
            :class="{ 'rotate-180': isChannelDropdownOpen }"
          />
        </button>
        <DropdownMenu
          v-if="isChannelDropdownOpen"
          :menu-items="channelMenuItems"
          class="absolute top-full mt-1 left-0 right-0 w-full z-50"
          @action="handleChannelAction"
        />
      </div>

      <!-- Language Filter -->
      <div class="relative w-44">
        <LanguageDropdown
          v-model="selectedLanguage"
          :placeholder="t('SETTINGS.TEMPLATES.FILTERS.ALL_LANGUAGES')"
          size="md"
          variant="outline"
          show-search
        />
      </div>

      <!-- Clear Filters -->
      <Button
        v-if="hasActiveFilters"
        icon="i-lucide-x"
        xs
        faded
        slate
        :label="'Clear'"
        @click="clearFilters"
      />

      <!-- Template count -->
      <div class="ml-auto text-xs text-n-slate-10">
        {{ filteredTemplates.length }} / {{ allTemplates.length }}
        {{ allTemplates.length === 1 ? 'template' : 'templates' }}
      </div>
    </div>

    <!-- Templates List -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('SETTINGS.TEMPLATES.LOADING')" />
    </div>

    <div
      v-else-if="!filteredTemplates.length && !hasActiveFilters"
      class="flex flex-col items-center justify-center py-16 text-center"
    >
      <span class="i-lucide-file-text text-4xl text-n-slate-8 mb-3" />
      <h3 class="text-base font-medium text-n-slate-11 mb-1">
        {{ t('SETTINGS.TEMPLATES.EMPTY_STATE.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-10 max-w-sm">
        {{ t('SETTINGS.TEMPLATES.EMPTY_STATE.DESCRIPTION') }}
      </p>
    </div>

    <div
      v-else-if="!filteredTemplates.length && hasActiveFilters"
      class="flex flex-col items-center justify-center py-12 text-center"
    >
      <span class="i-lucide-search text-3xl text-n-slate-8 mb-3" />
      <p class="text-sm text-n-slate-11">
        {{ t('SETTINGS.TEMPLATES.LIST.404') }}
      </p>
      <Button
        class="mt-3"
        xs
        faded
        slate
        label="Clear filters"
        @click="clearFilters"
      />
    </div>

    <div v-else class="flex-1 space-y-2 pb-4">
      <UnifiedTemplateRow
        v-for="template in filteredTemplates"
        :key="template.id"
        :template="template"
        @delete="openDelete"
        @navigate="navigateToInbox"
      />
    </div>

    <!-- Backdrop for mobile/overlay when popover is open -->
    <div v-if="showAddPopup" class="fixed inset-0 z-40" @click="hideAddPopup" />

    <!-- Delete Confirmation Modal -->
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedTemplate.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      :is-loading="isDeleting"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>

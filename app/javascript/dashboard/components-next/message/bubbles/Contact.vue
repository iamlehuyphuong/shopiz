<script setup>
import { computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import Avatar from 'next/avatar/Avatar.vue';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

const { attachments } = useMessageContext();

const $store = useStore();
const { t } = useI18n();

const { checkPermissions } = usePolicy();
const maskContactInfo = computed(() => !checkPermissions(['contact_manage']));
const { formatMessage } = useMessageFormatter(maskContactInfo);

const attachment = computed(() => {
  return attachments.value[0];
});

const phoneNumber = computed(() => {
  return attachment.value?.fallbackTitle || '';
});

const formattedPhoneNumber = computed(() => {
  if (!phoneNumber.value) return '';
  return formatMessage(phoneNumber.value, false, false, true);
});

const contactName = computed(() => {
  const { meta } = attachment.value ?? {};
  if (meta?.name) {
    return meta.name;
  }
  const { firstName, lastName } = meta ?? {};
  return `${firstName ?? ''} ${lastName ?? ''}`.trim();
});

const avatarUrl = computed(() => {
  const meta = attachment.value?.meta || {};
  return meta.avatarUrl || meta.avatar_url || '';
});

const qrCodeUrl = computed(() => {
  const meta = attachment.value?.meta || {};
  return meta.qrCodeUrl || meta.qr_code_url || '';
});

const rawPhoneNumber = computed(() => {
  if (!phoneNumber.value) return '';
  return phoneNumber.value.replace(/\D/g, '');
});

function getContactObject() {
  const contactItem = {
    name: contactName.value,
    phone_number: `+${rawPhoneNumber.value}`,
  };
  return contactItem;
}

async function filterContactByNumber(searchCandidate) {
  const query = {
    attribute_key: 'phone_number',
    filter_operator: 'equal_to',
    values: [searchCandidate],
    attribute_model: 'standard',
    custom_attribute_type: '',
  };

  const queryPayload = { payload: [query] };
  const contacts = await $store.dispatch('contacts/filter', {
    queryPayload,
    resetState: false,
  });
  return contacts.shift();
}

function openContactNewTab(contactId) {
  const accountId = window.location.pathname.split('/')[3];
  const url = `/app/accounts/${accountId}/contacts/${contactId}`;
  window.open(url, '_blank');
}

async function addContact() {
  try {
    let contact = await filterContactByNumber(rawPhoneNumber);
    if (!contact) {
      contact = await $store.dispatch('contacts/create', getContactObject());
      useAlert(t('CONTACT_FORM.SUCCESS_MESSAGE'));
    }
    openContactNewTab(contact.id);
  } catch (error) {
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('phone_number')) {
        useAlert(t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t('CONTACT_FORM.ERROR_MESSAGE'));
    }
  }
}

async function sendMessage() {
  try {
    let contact = await filterContactByNumber(rawPhoneNumber);
    if (!contact) {
      contact = await $store.dispatch('contacts/create', getContactObject());
      useAlert(t('CONTACT_FORM.SUCCESS_MESSAGE'));
    }
    // TODO: Implement direct sendMessage logic if needed.
    // For now, opening the contact tab.
    openContactNewTab(contact.id);
  } catch (error) {
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('phone_number')) {
        useAlert(t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t('CONTACT_FORM.ERROR_MESSAGE'));
    }
  }
}
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="contact">
    <div class="grid gap-4 min-w-64">
      <div class="flex items-start gap-3">
        <img
          v-if="avatarUrl"
          :src="avatarUrl"
          alt="Avatar"
          class="size-10 rounded-xl object-cover shrink-0"
        />
        <div
          v-else
          class="size-10 rounded-xl flex items-center justify-center bg-[#D6409F] shrink-0"
        >
          <div class="text-white size-5 i-teenyicons-user-circle-solid" />
        </div>

        <div class="space-y-0.5 overflow-hidden flex-1">
          <div class="truncate text-sm font-medium text-n-slate-12">
            {{ contactName }}
          </div>
          <div v-if="phoneNumber" class="truncate text-xs text-n-slate-11">
            <span
              v-dompurify-html="formattedPhoneNumber"
              class="prose prose-bubble [&>p]:m-0 [&>p]:inline"
            />
          </div>
          <div v-if="qrCodeUrl" class="mt-2">
            <img
              :src="qrCodeUrl"
              alt="QR Code"
              class="w-32 h-32 rounded-lg object-contain bg-white border border-n-container"
            />
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-2">
        <button
          class="w-full bg-n-solid-3 px-3 py-2 rounded-lg text-sm font-medium text-center border border-n-container transition-colors hover:bg-n-alpha-1"
          :title="$t('CONTACT_FORM.ZALO_ADD_FRIEND_TOOLTIP')"
          @click="addContact"
        >
          {{ $t('CONTACT_FORM.ZALO_ADD_FRIEND') }}
        </button>
        <button
          class="w-full bg-n-solid-3 px-3 py-2 rounded-lg text-sm font-medium text-center border border-n-container transition-colors hover:bg-n-alpha-1"
          :title="$t('CONTACT_FORM.ZALO_SEND_MESSAGE_TOOLTIP')"
          @click="sendMessage"
        >
          {{ $t('CONTACT_FORM.ZALO_SEND_MESSAGE') }}
        </button>
      </div>
    </div>
  </BaseBubble>
</template>

import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';

/**
 * Cleans and normalizes a list of labels.
 * @param {string} labels - A comma-separated string of labels.
 * @returns {string[]} An array of cleaned and unique labels.
 */
const cleanLabels = labels => {
  return labels
    .toLowerCase()
    .split(',')
    .filter(label => label.trim())
    .map(label => label.trim())
    .filter((label, index, self) => self.indexOf(label) === index);
};

export function useLabelSuggestions() {
  const store = useStore();
  const { isCloudFeatureEnabled } = useAccount();
  const appIntegrations = useMapGetter('integrations/getAppIntegrations');
  const currentChat = useMapGetter('getSelectedChat');
  const conversationId = computed(() => currentChat.value?.id);

  const captainTasksEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
  });

  const aiIntegration = computed(
    () =>
      appIntegrations.value.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      )?.hooks[0]
  );

  const isLabelSuggestionFeatureEnabled = computed(() => {
    // We still check if Captain tasks are globally enabled or if AI integration exists
    if (!aiIntegration.value) return false;

    // Check if the current conversation's inbox has label suggestions enabled
    const inboxId = currentChat.value?.inbox_id;
    if (inboxId) {
      const inbox = store.getters['inboxes/getInbox'](inboxId);
      return !!inbox?.label_suggestion_enabled;
    }
    return false;
  });

  const fetchIntegrationsIfRequired = async () => {
    if (!appIntegrations.value.length) {
      await store.dispatch('integrations/get');
    }
  };

  /**
   * Gets label suggestions for the current conversation.
   * @returns {Promise<string[]>} An array of suggested labels.
   */
  const getLabelSuggestions = async () => {
    if (!conversationId.value) return [];

    try {
      const result = await TasksAPI.labelSuggestion(conversationId.value);
      const {
        data: { message: labels },
      } = result;
      return cleanLabels(labels);
    } catch {
      return [];
    }
  };

  onMounted(() => {
    fetchIntegrationsIfRequired();
  });

  return {
    captainTasksEnabled,
    isLabelSuggestionFeatureEnabled,
    getLabelSuggestions,
  };
}

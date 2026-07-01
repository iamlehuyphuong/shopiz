import ApiClient from './ApiClient';

class InboxDailySummariesAPI extends ApiClient {
  constructor() {
    super('inbox_daily_summaries', { accountScoped: true });
  }
}

export default new InboxDailySummariesAPI();

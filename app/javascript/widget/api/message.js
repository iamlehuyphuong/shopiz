import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({ messageId, values }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      message: { submitted_values: values },
    });
  },
};

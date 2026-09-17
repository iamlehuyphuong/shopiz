/* global axios */

import ApiClient from './ApiClient';

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey }) {
    const url = searchKey ? `${this.url}?search=${searchKey}` : this.url;
    return axios.get(url);
  }

  create(data) {
    if (data.files?.length) {
      const formData = new FormData();
      formData.append('canned_response[short_code]', data.short_code);
      formData.append('canned_response[content]', data.content);
      data.files.forEach(file => {
        formData.append('canned_response[files][]', file);
      });
      return axios.post(this.url, formData);
    }
    return axios.post(this.url, { canned_response: data });
  }

  update(id, data) {
    if (data.files?.length || data.removed_file_ids?.length) {
      const formData = new FormData();
      formData.append('canned_response[short_code]', data.short_code);
      formData.append('canned_response[content]', data.content);
      if (data.files) {
        data.files.forEach(file => {
          formData.append('canned_response[files][]', file);
        });
      }
      if (data.removed_file_ids) {
        data.removed_file_ids.forEach(fileId => {
          formData.append('canned_response[removed_file_ids][]', fileId);
        });
      }
      return axios.patch(`${this.url}/${id}`, formData);
    }
    return axios.patch(`${this.url}/${id}`, { canned_response: data });
  }

  import(file) {
    const formData = new FormData();
    formData.append('import_file', file);
    return axios.post(`${this.url}/import`, formData);
  }

  export() {
    return axios.get(`${this.url}/export`, {
      responseType: 'blob',
    });
  }
}

export default new CannedResponse();

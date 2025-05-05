import axios from 'axios';

const { apiHost = '' } = window.salesmanConfig || {};
const wootAPI = axios.create({ baseURL: `${apiHost}/` });

export default wootAPI;

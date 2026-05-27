import axios from 'axios';

const { apiHost = '' } = window.flowifyConfig || {};
const wootAPI = axios.create({ baseURL: `${apiHost}/` });

export default wootAPI;

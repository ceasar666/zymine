import axios from 'axios';
type methods = 'delete' | 'post' | 'get' | 'put';

interface axiosParams {
  url: string;
  params?: Record<string, any>;
  data?: Record<string, any>;
  submitFrom?: boolean;
  method: methods;
  config?: {
    [key: string]: any;
  };
}
let axiosIns: any = axios.create({
  
});


axiosIns.defaults.responseType = 'json';

axiosIns.defaults.validateStatus = (status: number) => {
  return true;
};
axiosIns.interceptors.request.use((config: any) => {
  config['timeout'] = 60 * 1000 * 10;
  return config;
});

axiosIns.interceptors.response.use((response: any) => {
  let data = response.data;
  let status = response.status;
  if (status === 200) {
    if (data?.code === 401) {
      return Promise.resolve(data);
    }
    return Promise.resolve(data);
  } else {
    return Promise.reject(data);
  }
});

let ajaxMethod = ['get', 'post', 'put', 'delete'];
let api: any = {};

ajaxMethod.forEach((method) => {
  api[method] = (uri: string, data: object, config: object) => {
    return new Promise(function (resolve, reject) {
      axiosIns[method](uri, data, config)
        .then((response: any) => {
          resolve(response);
        })
        .catch((response: any) => {
          reject(response);
        });
    });
  };
});

let axiosService = async (params: axiosParams): Promise<any> => {
  if (params.method === 'get') {
    return await api.get(params.url, { params: params.params, ...params?.config }, {});
  } else if (params.method === 'delete') {
    return await api.delete(params.url, params.data, { ...params?.config });
  } else if (params.method === 'put') {
    return await api.put(params.url, params.data, { ...params?.config });
  } else {
    return await api.post(params.url, params.data, { ...params?.config });
  }
};

export default axiosService;

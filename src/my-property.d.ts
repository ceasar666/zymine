import VueRouter, { Route } from 'vue-router';

type Api<T> = { [key: string]: T };

interface Operating {
    visible: boolean;
    modelWidth?: string;
    modelHeight?: string;
    option: {
        head?: string;
        conter: string;
        onOk: Function;
    };
}

interface Load {
    loadingShow: () => {};
    tipShow: (tip: string) => {};
    tipSuccessShow: (value: string, time?: number) => {};
    tipWarningShow: (value: string) => {};
    tipErrorShow: (value: string, time?: number) => {};
    successFrame: (value: string, value2: string) => {};
    txid: (value: string) => {};
    hide: () => {};
}

declare module 'vue/types/vue' {
    interface Vue {}
}

declare global {
    interface Window {
        $router: VueRouter;
        $ElMessage: any;
        $wx: any;
        ethereum: any;
        downFlies: (data: any, filesName: string) => {};
    }
}

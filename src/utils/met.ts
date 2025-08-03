import BigNumber from 'bignumber.js';
import { ElMessage } from 'element-plus';
import moment from 'moment';

export enum MomentUnit {
    years = 'years',
    months = 'months',
    days = 'days',
    minutes = 'minutes',
    seconds = 'seconds',
}

export const $BigNumber = (val: string | number = 1) => {
    return new BigNumber(val);
};

export const $shiftedBy = (data: number | string, decimals: any): string => {
    if (!data) return '0';
    decimals = Number(decimals);
    return $BigNumber(data).shiftedBy(decimals).toFixed();
};

export const $shiftedByFixed = (data: string | number, decimals: number, acc: number = 4, roundingMode: BigNumber.RoundingMode = 1) => {
    if (!data) return 0;
    decimals = Number(decimals);
    return Number($BigNumber(data).shiftedBy(decimals).toFixed(acc, roundingMode));
};

export const $shiftedByString = (data: string | number, decimals: number, acc = 4) => {
    if (!data) return 0;
    decimals = Number(decimals);
    return $BigNumber(data).shiftedBy(decimals).toFixed(acc);
};

export const $shiftedByToBig = (data: string | number, decimals: number) => {
    if (!data) return 0;
    decimals = Number(decimals);
    return $BigNumber(data).shiftedBy(decimals).toFixed();
};

export const $toFixed = (data: any, acc: number) => {
    if ((!data && Number(data) !== 0) || String(data).indexOf('--') !== -1) return '--';
    return $BigNumber(data).toFixed(acc, 1);
};

export const $clearNoNum = (val: any): any => {
    val = val.replace(/[^\d.]/g, '');

    val = val.replace(/\.{2,}/g, '.');

    val = val.replace(/^\./g, '');

    val = val.replace('.', '$#$').replace(/\./g, '').replace('$#$', '.');

    return val;
};

export const $filterNumber = (e: any) => {
    function clearNoNum(val) {
        // 先把非数字的都替换掉，除了数字和.
        val = val.replace(/[^\d.]/g, '');

        // 保证只有出现一个.而没有多个.
        val = val.replace(/\.{2,}/g, '.');

        // 必须保证第一个为数字而不是.
        val = val.replace(/^\./g, '');

        // 保证.只出现一次，而不能出现两次以上
        val = val.replace('.', '$#$').replace(/\./g, '').replace('$#$', '.');

        return val;
    }
    e.target.value = clearNoNum(e.target.value);
};

export const $filterNumberVal = value => {
    function clearNoNum(val) {
        // 先把非数字的都替换掉，除了数字和.
        val = val.replace(/[^\d.]/g, '');

        // 保证只有出现一个.而没有多个.
        val = val.replace(/\.{2,}/g, '.');

        // 必须保证第一个为数字而不是.
        val = val.replace(/^\./g, '');

        // 保证.只出现一次，而不能出现两次以上
        val = val.replace('.', '$#$').replace(/\./g, '').replace('$#$', '.');

        return val;
    }
    return clearNoNum(String(value));
};

export const $onlyNumber = (val: any) => {
    return String(val).replace(/[^\d]/g, '');
};

export const $numFormat = (val: number | string, acc: number = 4, flag: boolean = true) => {
    if (!val || val.toString().indexOf('-') != -1) {
        return val;
    } else if (!flag) {
        return $BigNumber(val).toFixed(acc, 1);
    }

    let reg = /(\d)(?=(?:\d{3})+$)/g;
    val = $BigNumber(val).toFixed(acc, 1);
    const strAry = val.toString().split('.');
    return `${strAry[0].replace(reg, '$1,')}${strAry.length > 1 ? '.' + strAry[1] : ''}`;
};

export const $dateFormat = (date: string | undefined | Date, format: string = 'MM-dd hh:mm') => {
    if (!date) return '';
    return (new Date(date) as any).format(format);
};

export const $gt = (val: string | number, next: string | number) => {
    return new BigNumber(val).gt(next);
};

export const $lt = (val: string | number, next: string | number) => {
    return new BigNumber(val).lt(next);
};

export const $plus = (aryNumber: Array<string | number>, decimal: number = 2, round: any = 1): string | number => {
    const sum: any = aryNumber.reduce((acc: any, cur: any) => {
        return (new BigNumber(isNaN(acc) ? 0 : acc) as any).plus(isNaN(cur) ? 0 : cur);
    });
    // return $BigNumber(sum).sd(decimal, round).toFixed();
    return $shiftedByFixed(sum, 0, decimal);
    // return Number(sum.toFixed(decimal, 1));
};

export const $minus = (m1: string | number, m2: string | number, decimal: number = 2, round: any = 1): string | number => {
    const diff: any = new BigNumber(m1).minus(m2);
    // return $BigNumber(diff).sd(decimal, round).toFixed();
    return $shiftedByFixed(diff, 0, decimal);
};

export const $inputNumber = (): string => {
    return window.innerWidth < 960 ? 'number' : 'text';
};

export const $moreLessThan = (value: string | number, acc = 4, decimal: number = 4) => {
    const val = $BigNumber(value);
    let i = 0,
        _value = '0.';
    for (i; i < decimal - 1; i++) {
        _value = `${_value}0`;
    }
    _value = _value = `${_value}1`;

    if (Number(value) > 0) {
        return !val.isZero() && val.isLessThan(Number(_value)) ? `<${_value}` : val.isNaN() ? value : $shiftedByFixed(value, 0, acc);
    } else if (Number(value) == 0) {
        return 0;
    } else {
        return !val.isZero() && val.gt(-Number(_value)) ? `<-${_value}` : val.isNaN() ? value : $shiftedByFixed(value, 0, acc);
    }
};

// 只能输入正整数和负整数
export const $andNumber = (value: any) => {
    var val = String(value);
    var one = val.substr(0, 1);
    return one != '-' ? parseInt(val) || '' : one + (parseInt(val.substr(1, val.length)) || '');
};

export const $hash = (txHash: any, length: number = 4, lastLength?: number) => {
    if (!txHash) {
        return '--';
    }
    if (!lastLength && lastLength !== 0) lastLength = length;
    if (txHash.length > length + lastLength) {
        return txHash.substring(0, length) + '...' + txHash.substring(txHash.length - lastLength, txHash.length);
    } else {
        return txHash;
    }
};

export const $enumKey = (list: { [key: string]: string | number }[], value: string | number, target: string = 'name', key: string = 'key'): string | number => {
    if (!value && ![0, '0'].includes(value)) return '';
    const _tar = list.find(item => item[key] === value);
    return _tar[target] || '';
};

export const $trim = (event): string | number => {
    return event.target.value.trim();
};

export const $trimNumber = (event): string | number => {
    return event.target.value.replace(/[^\d^\.]+/g, '').trim();
};
export const $dealTimes = (endTime: number): Record<string, number> => {
    var difftime = endTime - new Date().getTime();
    if (difftime > 0) {
        var days = Math.floor(difftime / (24 * 3600 * 1000));
        var leave1 = difftime % (24 * 3600 * 1000);
        var hours = Math.floor(leave1 / (3600 * 1000));

        var leave2 = leave1 % (3600 * 1000);
        var minutes = Math.floor(leave2 / (60 * 1000));

        var leave3 = leave2 % (60 * 1000);
        var seconds = Math.round(leave3 / 1000) >= 60 ? 60 : Math.round(leave3 / 1000);
        return {
            days,
            hours,
            minutes,
            seconds,
        };
    } else {
        return {
            days: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
        };
    }
};

export const $dealAgoTimes = (startTime: string): Record<string, number> => {
    var difftime = new Date().getTime() - new Date(startTime).getTime();
    if (difftime > 0) {
        var days = Math.floor(difftime / (24 * 3600 * 1000));
        var leave1 = difftime % (24 * 3600 * 1000);
        var hours = Math.floor(leave1 / (3600 * 1000));

        var leave2 = leave1 % (3600 * 1000);
        var minutes = Math.floor(leave2 / (60 * 1000));

        var leave3 = leave2 % (60 * 1000);
        var seconds = Math.round(leave3 / 1000);
        let time = days + '天 ' + hours + '小时 ' + minutes + ' 分钟' + seconds + ' 秒';
        return {
            days,
            hours,
            minutes,
            seconds,
        };
    } else {
        return {
            days: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
        };
    }
};

export const $momentTimes = (date, type: string = 'start'): Record<string, number> => {
    let startT = moment(date);
    let curT = moment(new Date());
    let diff = type === 'start' ? startT.diff(curT) : curT.diff(startT);
    if (diff > 0) {
        const timeDiff = moment.duration(diff);
        return {
            months: Math.max(timeDiff.months(), 0),
            days: Math.max(timeDiff.days(), 0),
            hours: Math.max(timeDiff.hours(), 0),
            minutes: Math.max(timeDiff.minutes(), 0),
            seconds: Math.max(timeDiff.seconds(), 0),
        };
    } else {
        return {
            months: 0,
            days: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
        };
    }
    const timeDiff = moment.duration(diff);
    console.log('timeDiff::', diff, timeDiff.days(), timeDiff.hours(), timeDiff.minutes(), timeDiff.seconds());
    return {
        // months: Math.max(timeDiff.months(), 0),
        days: Math.max(timeDiff.days(), 0),
        hours: Math.max(timeDiff.hours(), 0),
        minutes: Math.max(timeDiff.minutes(), 0),
        seconds: Math.max(timeDiff.seconds(), 0),
    };
};
export const $diffDate = (date, unit: MomentUnit = MomentUnit.days): number => {
    let startT = moment(date);
    let endT = moment(new Date());
    return endT.diff(startT, unit);
};

export async function $delay(ms: number) {
    return new Promise(res => setTimeout(res, ms));
}

export const $getQuery = () => {
    if (typeof window !== 'undefined') {
        const href = window.location.href;
        const query = href.substring(href.indexOf('?') + 1);
        const types = query.split('&');
        let obj = {},
            i = 0;
        for (i; i < types.length; i++) {
            const pari = types[i].split('=');
            obj[pari[0]] = pari[1];
        }
        return obj;
    } else {
        return {};
    }
};

export const $calcDate = (data: any, format: string = 'yyyy-MM-dd hh:mm:ss') => {
    return (new Date(data) as any).format(format);
};

export const $copy = (text: any): Promise<void> => {
    try {
        var textArea: any = document.createElement('textarea');
        textArea.style.position = 'fixed';
        textArea.style.top = 0;
        textArea.style.left = 0;
        textArea.style.width = '2em';
        textArea.style.height = '2em';
        textArea.style.padding = 0;
        textArea.style.border = 'none';
        textArea.style.outline = 'none';
        textArea.style.boxShadow = 'none';
        textArea.style.background = 'transparent';
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        try {
            var successful = document.execCommand('copy');
            console.log(successful);
        } catch (err) {
            console.log('Oops, unable to copy');
        }
        document.body.removeChild(textArea);
        ElMessage.success('複製成功');
        // message.success('Copy Successfully')
        return Promise.resolve();
    } catch (e) {
        ElMessage.error('複製失敗');
        console.error('copy error', e);
        return Promise.reject();
    }
};

export const $baseUrl = (url?: string) => {
    let _url = '';
    if (!url) url = typeof window !== 'undefined' ? window.location.href : '';
    if (url.indexOf('localhost') !== -1 || url.indexOf('-test') !== -1 || url.indexOf('-dev') !== -1) {
        _url = 'https://nft-aggregator-asset-test.burgerswap.org/';
    } else {
        _url = `https://nft-aggregator-asset.burgerswap.org/`;
    }
    return _url;
};

export const $toExponential = (val: string | number) => {
    let _val = '';
    if (String(val).length > 10) {
        _val = Number(val).toExponential(2);
    } else {
        _val = $toFixed(val, 2);
    }
    return _val;
};

export const $sleep = (ms: number): Promise<Function> => {
    return new Promise(resolve => setTimeout(resolve, ms));
};

export const $formatNumber = (num: number): string => {
    if (num >= 1000000000) {
        return Number((num / 1000000000).toFixed(2)) + 'B';
    } else if (num >= 1000000) {
        return Number((num / 1000000).toFixed(2)) + 'M';
    } else if (num >= 1000) {
        return Number((num / 1000).toFixed(2)) + 'K';
    }
    return num.toString();
};

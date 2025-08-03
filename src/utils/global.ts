
export {};

(Date as any).prototype.format = function (fmt: any) {
  let o: any = {
    'M+': this.getMonth() + 1, //月份
    'd+': this.getDate(), //日
    'h+': this.getHours(), //小时
    'm+': this.getMinutes(), //分
    's+': this.getSeconds(), //秒
    'q+': Math.floor((this.getMonth() + 3) / 3), //季度
    S: this.getMilliseconds() //毫秒
  };
  if (/(y+)/.test(fmt)) {
    fmt = fmt.replace(
      RegExp.$1,
      (this.getFullYear() + '').substr(4 - RegExp.$1.length)
    );
  }
  for (let k in o) {
    if (new RegExp('(' + k + ')').test(fmt)) {
      fmt = fmt.replace(
        RegExp.$1,
        RegExp.$1.length === 1 ? o[k] : ('00' + o[k]).substr(('' + o[k]).length)
      );
    }
  }
  return fmt;
};

/**
 * formatMoney
 * @param number 传入的数字。必选
 * @param places  小数点的位数。可选，默认为两位小数
 * @param symbol  数字最后的符号 。可选，默认为美元字符“￥”
 * @param thousand  千分位分隔符。可选，默认为“，”
 * @param decimal  小数位分隔符。可选，默认为“.”
 */
(Number as any).prototype.formatMoney = function (
  places: number = 2,
  symbol: string = '',
  thousand: string = ',',
  decimal: string = '.'
) {
  let number: any = this || 0;
  places = !isNaN((places = Math.abs(places))) ? places : 2;
  symbol = symbol !== undefined ? symbol : '$';
  thousand = thousand || ',';
  decimal = decimal || '.';
  var negative = number < 0 ? '-' : '',
    i: any =
      parseInt((number = Math.abs(+number || 0).toFixed(places)), 10) + '',
    j: any = i.length > 3 ? i.length % 3 : 0;
  return (
    negative +
    (j ? i.substr(0, j) + thousand : '') +
    i.substr(j).replace(/(\d{3})(?=\d)/g, '$1' + thousand) +
    (places
      ? decimal +
        Math.abs(number - i)
          .toFixed(places)
          .slice(2)
      : '') +
    symbol
  );
};

//Copy Text
(Window as any).prototype.copy = (text: any): Promise<void> => {
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
    return Promise.resolve();
  } catch (e) {
    console.error('copy error', e);
    return Promise.reject();
  }
};
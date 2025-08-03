import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';
import router from './routes';
import store from './store';
import 'utils/global';
import 'element-plus/dist/index.css';
import './assets/style/reset.scss';
import App from './App.vue';
import lange from './lang';
import ElementPlus from 'element-plus';
import zhCn from 'element-plus/dist/locale/zh-cn.mjs';
import * as ElementPlusIconsVue from '@element-plus/icons-vue';

const i18n = createI18n({
    messages: lange,
    legacy: false,
    locale: localStorage.lang || 'zh',
});
// console.log = () => {}
const app = createApp(App);
app.use(ElementPlus, {
    locale: zhCn,
})
    .use(i18n)
    .use(router)
    .use(store)
    .mount('#app');
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
    app.component(key, component);
}

<template>
    <header>
        <div class="header flex_between">
            <div class="left">
                <img class="logo" src="~images/base/logo.png" />
                <!-- <span>BXC</span> -->
                <!-- <img class="logo-font" src="~images/base/logo-font.png" /> -->
            </div>
            <div class="right">
                <!-- <img class="link" @click="jump(blockChain.link.tg)" src="~images/base/003.png" alt="" /> -->
                <!-- <el-popover popper-class="lang-popover" trigger="click" placement="bottom" v-model:visible="state.openLang">
                    <template #reference>
                        <img class="link" src="~images/base/lang.svg" alt="" />
                    </template>
                    <div class="menu-list">
                        <div v-for="(item, index) in state.langList" :key="index" class="item" @click="setLang(item)">
                            {{ item.title }}
                        </div>
                    </div>
                </el-popover> -->
                <div class="wallet" @click="connectWallet()">
                    {{ blockChain.account ? $hash(blockChain.account, 7, 5) : '链接钱包' }}
                </div>
                <!-- <img class="menu" @click="openDialog(!state.open)" src="~images/base/006.png" alt="" /> -->
            </div>
        </div>
    </header>
    <div class="dialog_menu" v-if="state.open">
        <div class="mask" @click="openDialog(false)"></div>
        <div class="main">
            <img class="close" @click="openDialog(false)" src="/images/close.png" alt="" />

            <div class="nav">
                <div class="lib" v-for="(item, index) of state.menu_list" :key="index" @click="jump(item.path)">
                    {{ item.name }}
                </div>
            </div>

            <div class="link">
                MALA
                <!-- <img src="~images/base/002.png" alt="" /> -->
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { getCurrentInstance, reactive } from 'vue';
import { storeToRefs } from 'pinia';
import { useBlockChain } from '@/store/chain';
import { $hash } from '@/utils/met';
import { ElMessage } from 'element-plus';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { Check } from '@element-plus/icons-vue';

import en from '../../assets/images/lang/en.svg';
import zhTW from '../../assets/images/lang/zh-TW.svg';

const route = useRoute();

const { t, locale } = useI18n();
const { proxy } = getCurrentInstance();
const router = useRouter();
const blockChain = useBlockChain();
const { account } = storeToRefs(blockChain);
let state = reactive({
    open: false,
    openLang: false,
    langList: [
        { title: 'English', value: 'en', icon: en },
        { title: '中文', value: 'zh', icon: zhTW },
    ],
    menu_list: [
        { name: '首页', path: '/' },
        { name: 'NFT', path: '' },
        { name: '质押挖矿', path: '' },
        { name: '应用市场', path: '' },
        { name: '数码元宇宙', path: '' },
        { name: '电报社区', path: blockChain.link.tg },
        { name: '官方推特', path: blockChain.link.tw },
    ],
});
// const setLange = () => {
//     proxy.$i18n.locale = proxy.$i18n.locale === 'zh' ? 'en' : 'zh';
//     blockChain.setLange(proxy.$i18n.locale);
// };

const setLang = item => {
    proxy.$i18n.locale = item.value;
    blockChain.setLange(proxy.$i18n.locale);
    state.openLang = false;
};

const openDialog = flag => {
    state.open = flag;
};
const connectWallet = async () => {
    if (!account.value) {
        try {
            await blockChain.disconnect();
            await blockChain.connectWallet();
        } catch (e: any) {
            ElMessage.error(e?.message ?? 'error');
        }
    }
};
const jump = path => {
    if (path.indexOf('https:') !== -1) {
        window.open(path);
    } else if (path) {
        router.push(path);
    } else {
        ElMessage.warning({
            showClose: true,
            message: 'Coming Soon',
            type: 'warn',
            duration: 2500,
        });
    }
    state.open = false;
};
</script>

<style scoped lang="scss">
header {
    width: 100%;
    padding: 0.05rem 0.15rem;
    position: fixed;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    z-index: 99;
    max-width: 450px;
    background: #000;
    .header {
        width: 100%;
        position: relative;
        display: flex;
        justify-content: space-between;
        align-items: center;
        .left {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 0.08rem;
            .logo {
                height: 0.44rem;
            }
            span {
                font-family: Alimama Agile VF, Alimama Agile VF;
                font-weight: 400;
                font-size: 0.2rem;
                color: #ffffff;
                line-height: 21px;
            }
            .menu {
                height: 0.28rem;
                margin-right: 0.2rem;
                cursor: pointer;
            }
            .logo-font {
                height: 0.3rem;
                margin-left: 0.06rem;
            }
        }
        .right {
            display: flex;
            align-items: center;
            gap: 0.11rem;
            /* .lang {
                height: 0.3rem;
                margin-right: 0.15rem;
            } */
            .link {
                height: 0.28rem;
            }
            .lang {
                /* margin-right: 0.13rem; */
                cursor: pointer;
                position: relative;
                display: flex;
                align-items: center;
                .icon {
                    width: 0.25rem;
                }
            }
            .menu {
                height: 0.34rem;
            }
            .wallet {
                min-width: 1.5rem;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 0.05rem;
                padding: 0 0.15rem;
                font-size: 0.15rem;
                color: #fff;
                height: 0.3rem;
                border-radius: 0.2rem;
                background: linear-gradient(180deg, #7fff00 0%, #028100 100%);
                img {
                    height: 0.18rem;
                }
            }
        }
    }
}
.dialog_menu {
    position: fixed;
    width: 100%;
    /* height: calc(100vh - 0.54rem);
    min-height: calc(100vh - 0.54rem); */
    height: 100vh;
    bottom: 0;
    left: 0;
    z-index: 99;
    .mask {
        position: absolute;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.36);
    }
    .main {
        position: absolute;
        height: 100%;
        right: 0;
        top: 0;
        background: #74bf7c;
        padding: 0.6rem 0.12rem 0.2rem;
        z-index: 3;
        width: 1.5rem;
        .close {
            position: absolute;
            top: 0.2rem;
            right: 0.12rem;
            border-radius: 0.04rem;
            cursor: pointer;
            height: 0.25rem;
        }
        .nav {
            width: 100%;
            .lib {
                width: 100%;
                height: 0.3rem;
                line-height: 0.28rem;
                font-size: 0.11rem;
                color: #3d3d3d;
                margin-bottom: 0.11rem;
                cursor: pointer;
                padding-right: 0.15rem;
                text-align: right;
                background: #fcfcfc;
                border: 1px solid #d8d8d8;
                border-radius: 0.03rem;
            }
        }
        .link {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.12rem;
            font-size: 0.2rem;
            color: #ffffff;
            margin-top: 0.5rem;
            img {
                height: 0.4rem;
            }
        }
    }
}
</style>
<style lang="scss">
.lang-popover {
    background: #feffd2 !important;
    border: none !important;
    border-radius: 0.04rem !important;
    padding: 0 !important;
    .el-popper__arrow {
        &::before {
            background: #feffd2 !important;
            border-color: rgba(255, 255, 255, 0.2) !important;
        }
    }
    .menu-list {
        padding: 0.05rem 0 0.08rem;
        .item {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 0.13rem;
            color: #3d3d3d;
            line-height: 1.8;
            margin-bottom: 0.05rem;
            transition: background-color 0.2s;
            &:last-child {
                border-bottom: none;
            }
            &:last-child {
                margin-bottom: 0;
            }
            &.active {
                background: #fd7513;
            }
        }
    }
}
</style>

<template>
    <main class="container">
        <div class="mask" :class="{ show: state.show }">
            <div class="content" @click="init">
                <!-- <img src="./assets/images/home/202.gif" alt="" /> -->
                <div>{{ t('base.login fail') }}</div>
            </div>
        </div>
        <div class="main" v-if="!state.show">
            <router-view :key="route.path" />
        </div>
    </main>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router';
import { reactive, onMounted, watch } from 'vue';
import { useBlockChain } from '@/store/chain';
import { useI18n } from 'vue-i18n';
const { t } = useI18n();

const route = useRoute();
const router = useRouter();
const blockChain = useBlockChain();

const state = reactive({
    socket: null,
    inviter: null,
    show: false,
});

watch(
    () => blockChain.account,
    () => {
        // init();
    }
);

watch(
    () => route.query,
    () => {
        console.log('route', route);
        if (route.query?.id) {
            blockChain.setInviter((route.query?.id ?? '') as any);
        } else {
            const inviter = window.sessionStorage.getItem('inviter');
            inviter && blockChain.setInviter(inviter);
        }
    }
);

const init = async () => {
    try {
        await blockChain.signer.signMessage(`Auth BXC at:${Date.now()}`);
        state.show = false;
    } catch (e) {
        state.show = true;
    }
};

onMounted(() => {
    blockChain.init_blockChain();
    blockChain.connectWallet();

    // setTimeout(() => {
    //     state.show = false;
    // }, 3000);

    if (window.ethereum) {
        window.ethereum.on('accountsChanged', async function (accounts) {
            await blockChain.connectWallet();
        });
        //当所连接网络ID变化时触发
        window.ethereum.on('chainChanged', networkIDstring => {
            console.log('链切换', networkIDstring);
            window.location.reload();
        });
    }
});
</script>

<style scoped lang="scss">
.container {
    width: 100%;
    max-width: 450px;
    height: 100vh;
    max-height: 100vh;
    overflow: hidden;
    margin: 0 auto;
    position: relative;
    color: #fff;
    .mask {
        position: fixed;
        width: 100vw;
        height: 100vh;
        max-width: 450px;
        top: 0;
        left: 50%;
        transform: translateX(-50%);
        z-index: 999;
        background: url('./assets/images/home/201.jpg') no-repeat center center;
        background-size: 100% 100%;
        opacity: 0;
        transition: all 0.6s;
        z-index: -1;

        &.show {
            opacity: 1;
            z-index: 999;
        }
        .content {
            position: absolute;
            top: 40%;
            left: 50%;
            transform: translate(-50%, -50%);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            width: 100%;
            gap: 0.2rem;
            img {
                height: 1.4rem;
            }
            div {
                font-size: 0.15rem;
                color: #fd7513;
                line-height: 0.22rem;
            }
        }
    }

    .main {
        width: 100%;
        height: 100vh;
        max-height: 100vh;
        margin: 0 auto;
        position: relative;
        z-index: 3;
        overflow-x: hidden;
        overflow-y: auto;

        section {
            /* margin-top: 0.15rem; */
        }
        .router {
            @media screen and (min-width: 450px) {
                background: none;
            }
        }
        footer {
            position: fixed;
            bottom: 0;
            height: 0.64rem;
            left: 50%;
            transform: translateX(-50%);
            z-index: 99;
            width: 100%;
            max-width: 450px;
            padding: 0 0.2rem;
            .cont {
                display: flex;
                height: 100%;
                justify-content: center;
            }
            .navs {
                width: 0.44rem;
                height: 100%;
                display: flex;
                justify-content: center;
                cursor: pointer;
                transition: all 0.2s;
                padding-top: 0.12rem;
                margin-right: 0.5rem;
                transition: all 0.2s;
                img {
                    height: 0.2rem;
                    width: 0.2rem;
                }
                &:last-child {
                    margin-right: 0;
                }
                &.active {
                    border-radius: 0.22rem 0.22rem 0 0;
                    background: #254ae5;
                    position: relative;
                    &::after {
                        content: '';
                        width: 0.04rem;
                        height: 0.04rem;
                        background: #fff;
                        border-radius: 50%;
                        position: absolute;
                        top: 0.4rem;
                        left: 50%;
                        transform: translateX(-50%);
                    }
                }
            }
        }
        .dialog {
            width: 100%;
            position: fixed;
            top: 0;
            left: 0;
            height: 100%;
            z-index: 999;
            width: 100%;

            .mask {
                width: 100%;
                position: absolute;
                top: 0;
                left: 0;
                height: 100%;
                background: rgba(0, 0, 0, 0.6);
            }
            .section {
                position: absolute;
                z-index: 999;
                width: calc(100% - 0.4rem);
                max-width: calc(450px - 0.4rem);
                top: 50%;
                left: 50%;
                transform: translate(-50%, -70%);
                border-radius: 0.24rem;
                background: #fff;
                padding: 0.4rem 0.24rem;
                text-align: center;
                color: #000;
                font-family: Source Han Sans CN;
                div {
                    font-size: 0.18rem;
                    font-weight: 500;
                    line-height: 0.27rem;
                    margin-bottom: 0.27rem;
                }
                svg,
                img {
                    width: 0.4rem;
                    height: 0.4rem;
                    /* margin: 0.27rem 0; */
                    animation: rotate 1s linear infinite;
                }
                p {
                    margin-top: 0.27rem;
                    font-size: 16px;
                    line-height: 0.24rem;
                }
            }
        }
    }
}
</style>

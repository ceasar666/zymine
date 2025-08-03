<template>
    <div class="footer">
        <div class="item" v-for="item in nav" :key="item.path" :class="{ active: route.path === item.path }" @click="jump(item.path)">
            <!-- <img :src="`/images/nav/${route.path === item.path ? item.icon + '-active' : item.icon}.png`" alt="" /> -->
            <p>{{ item.name }}</p>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const route = useRoute();
const router = useRouter();
const nav = ref([
    {
        name: '漲跌',
        icon: 'home',
        path: '/',
    },
    {
        name: '排行',
        icon: 'rank',
        path: '/rank',
    },
    {
        name: '邀請',
        icon: 'invite',
        path: '/invite',
    },
]);
const jump = path => {
    router.push(path);
    window.scrollTo(0, 0);
};
</script>

<style scoped lang="scss">
.footer {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.1rem;
    width: calc(100% - 0.26rem);
    height: 0.6rem;
    background: #303030;
    border-radius: 56px 56px 56px 56px;
    position: fixed;
    bottom: 0.3rem;
    left: 50%;
    transform: translateX(-50%);
    align-items: center;
    z-index: 99;
    .item {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.03rem;
        &.active {
            p {
                color: #fff;
            }
        }
        img {
            width: 0.22rem;
        }
        p {
            font-size: 0.13rem;
            line-height: 1.5;
            color: #909090;
        }
    }
}
</style>

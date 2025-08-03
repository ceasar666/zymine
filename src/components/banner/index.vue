<template>
    <div class="banner">
        <img src="~images/banner/banner.png" alt="" srcset="" class="img" />
        <section></section>
        <img class="label" src="~images/banner/nobel.png" alt="" srcset="" />
    </div>
    <router-view />
    <Footer />
</template>

<script setup lang="ts">
import Footer from '../footer/index.vue';
</script>

<style scoped lang="scss">
.banner {
    padding-top: 0.5rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-bottom: 0.16rem;
    .img {
        width: 100%;
    }
    section {
        margin-top: -1.3rem;
        text-align: center;
        .title {
            font-family: YouSheBiaoTiHei;
            font-weight: 400;
            font-size: 0.5rem;
            color: #ffffff;
            line-height: 1;
            margin-bottom: 0.26rem;
        }
        .tip {
            font-family: YouSheBiaoTiHei;
            font-size: 0.21rem;
            color: #ffffff;
            line-height: 0.35rem;
            span {
                color: #c700ff;
            }
        }
    }
    .label {
        width: 1.46rem;
        margin-top: 0.17rem;
    }
}
</style>

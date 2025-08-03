import { createRouter, createWebHistory, Router, createWebHashHistory } from 'vue-router';

const router: Router = createRouter({
    history: createWebHashHistory(),
    routes: [
        {
            path: '/',
            component: () => import('@/components/layout/index.vue'),
            children: [
                {
                    path: '/',
                    component: () => import('@/pages/home/index.vue'),
                },
                // {
                //     path: '/rank',
                //     component: () => import('@/pages/rank/index.vue'),
                // },
                // {
                //     path: '/invite',
                //     component: () => import('@/pages/invite/index.vue'),
                // },
            ],
        },

        // {
        //     path: '/:(*)',
        //     redirect: '/',
        // },
    ],
});

export default router;

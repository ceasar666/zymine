/* eslint-disable */
declare module '*.vue' {
  const echarts: any
  export default echarts
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

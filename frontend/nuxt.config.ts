// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: ['@nuxt/eslint', '@nuxt/test-utils/module'],

  // SPAにする。nuxt generate でできたファイルを Cloudflare Pages に置くだけで動く
  ssr: false,

  devtools: { enabled: true },

  app: {
    head: {
      htmlAttrs: { lang: 'ja' },
      title: 'site-health',
      // 管理画面も共有レポートも、検索エンジンに載せない
      meta: [{ name: 'robots', content: 'noindex' }],
    },
  },

  runtimeConfig: {
    public: {
      // APIのURL。SPAなので、この値はビルドのときにファイルへ埋め込まれる。
      // 本番はビルドのときに環境変数 NUXT_PUBLIC_API_BASE で渡す
      apiBase: 'http://localhost:3001',
    },
  },

  compatibilityDate: '2025-07-15',
})

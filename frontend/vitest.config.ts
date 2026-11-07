import { defineVitestConfig } from '@nuxt/test-utils/config'

export default defineVitestConfig({
  test: {
    // Nuxtの中（自動インポートやruntimeConfigが使える状態）でテストを動かす。DOMはhappy-dom
    environment: 'nuxt',
    // test/nuxt/ は、Nuxtが作るtsconfigで型チェックの対象に入っている
    include: ['test/nuxt/**/*.test.ts'],
  },
})

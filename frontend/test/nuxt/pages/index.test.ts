import { mountSuspended } from '@nuxt/test-utils/runtime'
import { describe, expect, it } from 'vitest'
import { useRuntimeConfig } from '#imports'
import IndexPage from '~/pages/index.vue'

describe('トップページ（仮）', () => {
  it('サービス名を表示する', async () => {
    const wrapper = await mountSuspended(IndexPage)

    expect(wrapper.find('h1').text()).toBe('site-health')
  })
})

describe('runtimeConfig', () => {
  it('手元では、APIのURLが http://localhost:3001 になる', () => {
    expect(useRuntimeConfig().public.apiBase).toBe('http://localhost:3001')
  })
})

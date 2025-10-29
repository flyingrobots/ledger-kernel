import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(defineConfig({
  base: process.env.DOCS_BASE || '/',
  title: 'Ledger-Kernel',
  description: 'Git-native, verifiable, append-only ledger specification',
  themeConfig: {
    nav: [
      { text: 'Spec', link: '/spec/' },
      { text: 'Model', link: '/model/' },
      { text: 'Reference', link: '/reference/' },
      { text: 'Architecture', link: '/architecture/' },
      { text: 'Compliance', link: '/compliance/' },
      { text: 'Implementation', link: '/implementation/' },
      { text: 'Modes', link: '/modes' },
      { text: 'Decisions', link: '/decisions' }
    ],
    sidebar: {
      '/spec/': [
        { text: 'Specification', items: [ { text: 'Spec v1.0.0', link: '/spec/' } ] }
      ],
      '/model/': [
        { text: 'Model', items: [ { text: 'Formal Model', link: '/model/' } ] }
      ],
      '/reference/': [
        { text: 'API', items: [ { text: 'Reference API', link: '/reference/' } ] }
      ],
      '/architecture/': [
        { text: 'Architecture', items: [ { text: 'System Architecture', link: '/architecture/' } ] }
      ],
      '/compliance/': [
        { text: 'Compliance', items: [ { text: 'Compliance Suite', link: '/compliance/' } ] }
      ],
      '/implementation/': [
        { text: 'Implementation', items: [ { text: 'libgitledger details', link: '/implementation/' } ] }
      ],
      '/': [
        {
          text: 'Overview',
          items: [
            { text: 'Home', link: '/' },
            { text: 'Modes', link: '/modes' },
            { text: 'Decisions', link: '/decisions' },
            { text: 'Execution Checklist', link: '/checklist' }
          ]
        }
      ]
    }
  }
}), {
  mermaid: {
    theme: { light: 'default', dark: 'dark' },
    securityLevel: 'strict'
  }
})

import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(defineConfig({
  base: process.env.DOCS_BASE || '/',
  title: 'Ledger-Kernel',
  description: 'Git-native, verifiable, append-only ledger specification',
  themeConfig: {
    nav: [
      { text: 'Modes', link: '/modes' },
      { text: 'Decisions', link: '/decisions' }
    ],
    sidebar: [
      {
        text: 'Overview',
        items: [
          { text: 'Home', link: '/' },
          { text: 'Modes', link: '/modes' },
          { text: 'Decisions', link: '/decisions' }
        ]
      }
    ]
  }
}), {
  // Mermaid plugin options
  mermaid: {
    theme: { light: 'default', dark: 'dark' },
    securityLevel: 'strict'
  }
})

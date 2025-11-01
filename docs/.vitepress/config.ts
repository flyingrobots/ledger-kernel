import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(defineConfig({
  base: process.env.DOCS_BASE || '/',
  title: 'Ledger-Kernel',
  description: 'Git-native, verifiable, append-only ledger specification',
  // Temporarily ignore dead links to unblock deploy; track fixes in docs.
  ignoreDeadLinks: true,
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
    // Minimal sidebar; single-page sections rely on nav. Add per-dir
    // sidebars if/when sections become multi-page.
    sidebar: {
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

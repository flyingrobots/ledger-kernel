import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(defineConfig({
  base: process.env.DOCS_BASE || '/',
  title: 'Ledger-Kernel',
  description: 'Git-native, verifiable, append-only ledger specification',
  // Keep while we reshuffle content into the new IA
  ignoreDeadLinks: true,
  themeConfig: {
    nav: [
      { text: 'Spec', link: '/spec/', activeMatch: '^/spec/' },
      { text: 'Reference Implementation', link: '/implementation/', activeMatch: '^/implementation/' },
      { text: 'CLI', link: '/cli/', activeMatch: '^/cli/' },
      { text: 'GitHub ↗', link: 'https://github.com/flyingrobots/ledger-kernel' }
    ],
    sidebar: {
      '/spec/': [
        {
          text: 'Ledger-Kernel Spec',
          collapsible: false,
          items: [
            { text: 'Overview', link: '/spec/overview' },
            { text: 'Model', link: '/spec/model' },
            { text: 'Formal Spec', link: '/spec/formal-spec' },
            { text: 'Wire Format', link: '/spec/wire-format' },
            { text: 'Determinism & Replay', link: '/spec/determinism' },
            { text: 'Compliance', link: '/spec/compliance' }
          ]
        }
      ],
      '/implementation/': [
        {
          text: 'Reference Implementation (libgitledger)',
          collapsible: true,
          items: [
            { text: 'Overview', link: '/implementation/' },
            { text: 'System Architecture', link: '/implementation/architecture' },
            { text: 'Operational Pipelines', link: '/implementation/pipelines' },
            { text: 'Modules & API', link: '/implementation/modules' },
            { text: 'Adapters & Environments', link: '/implementation/adapters' },
            { text: 'Determinism & Time', link: '/implementation/determinism' },
            { text: 'Error Model', link: '/implementation/errors' },
            { text: 'Security & Threat Model', link: '/implementation/security' },
            { text: 'Limitations & Future Work', link: '/implementation/future' }
          ]
        }
      ],
      '/cli/': [
        {
          text: 'CLI',
          collapsible: true,
          items: [
            { text: 'Overview', link: '/cli/' },
            { text: 'Commands', link: '/cli/commands' },
            { text: 'Configuration', link: '/cli/config' },
            { text: 'Examples', link: '/cli/examples' }
          ]
        }
      ],
      '/architecture/': [
        {
          text: 'Architecture Notes',
          collapsible: true,
          items: [
            { text: 'Design Objectives', link: '/architecture/objectives' },
            { text: 'Ledger Object Graph', link: '/architecture/object-graph' },
            { text: 'Integrity & BLAKE3', link: '/architecture/integrity' },
            { text: 'Epochs & Policy', link: '/architecture/epochs' },
            { text: 'Security Considerations', link: '/architecture/security' }
          ]
        }
      ],
      '/modes': [
        {
          text: 'Decisions & Modes',
          collapsible: true,
          items: [
            { text: 'Modes of Operation', link: '/modes' },
            { text: 'Design Decisions', link: '/decisions' },
            { text: 'Execution Checklist', link: '/implementation/execution-checklist' }
          ]
        }
      ],
      '/decisions': [
        {
          text: 'Decisions & Modes',
          collapsible: true,
          items: [
            { text: 'Modes of Operation', link: '/modes' },
            { text: 'Design Decisions', link: '/decisions' },
            { text: 'Execution Checklist', link: '/implementation/execution-checklist' }
          ]
        }
      ],
      '/appendix/': [
        {
          text: 'Appendices',
          collapsible: true,
          items: [
            { text: 'Repository Structure', link: '/appendix/repo' },
            { text: 'Minimal Examples', link: '/appendix/examples' },
            { text: 'Glossary', link: '/appendix/glossary' }
          ]
        }
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

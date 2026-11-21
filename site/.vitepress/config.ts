import { defineConfig } from 'vitepress';

export default defineConfig({
  base: '/regexes/',
  title: 'regexes',
  description: 'Regular expressions named for what they match',
  lang: 'en-US',
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    siteTitle: 'regexes',
    search: {
      provider: 'local',
    },
    nav: [
      { text: 'Quick Start', link: '/getting-started/' },
      { text: 'Concepts', link: '/concepts/expressions' },
      { text: 'Guides', link: '/guides/your-own-patterns' },
      { text: 'Patterns', link: '/reference/patterns' },
      { text: 'Design', link: '/design/decisions' },
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Home', link: '/' },
          { text: 'Quick Start', link: '/getting-started/' },
        ],
      },
      {
        text: 'Concepts',
        items: [
          { text: 'Expressions', link: '/concepts/expressions' },
          { text: 'Sets of Characters', link: '/concepts/character-sets' },
          { text: 'Composition', link: '/concepts/composition' },
        ],
      },
      {
        text: 'Guides',
        items: [
          { text: 'Your Own Patterns', link: '/guides/your-own-patterns' },
          { text: 'JavaScript and JSON Schema', link: '/guides/javascript-and-json-schema' },
        ],
      },
      {
        text: 'Reference',
        items: [{ text: 'Named Patterns', link: '/reference/patterns' }],
      },
      {
        text: 'Design',
        items: [
          { text: 'Naming', link: '/design/naming' },
          { text: 'Decisions', link: '/design/decisions' },
        ],
      },
    ],
    socialLinks: [{ icon: 'github', link: 'https://github.com/sebscholl-labs/regexes' }],
  },
});

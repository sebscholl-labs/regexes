import { defineConfig } from 'vitepress';
import llmstxt from 'vitepress-plugin-llms';

// What llms.txt says first, before its table of contents: where an assistant should start.
const llmsDetails = [
  'Before writing, reviewing or replacing a regular expression in a Ruby project that uses this gem, read',
  '[Instructions for AI Assistants](https://sebscholl-labs.github.io/regexes/guides/ai-instructions.md): the',
  'procedure to follow, the rules, recipes for common needs, and the whole API. The',
  '[Named Patterns](https://sebscholl-labs.github.io/regexes/reference/patterns.md) reference lists every',
  'pattern with what it matches, refuses and captures; use only names it lists.',
  '[llms-full.txt](https://sebscholl-labs.github.io/regexes/llms-full.txt) holds every page in one file.',
].join(' ');

export default defineConfig({
  base: '/regexes/',
  title: 'regexes',
  description: 'Named, tested regular expressions for Ruby',
  lang: 'en-US',
  cleanUrls: true,
  lastUpdated: true,
  vite: {
    // llms.txt, llms-full.txt and a Markdown copy of every page, built from these docs so they never drift.
    plugins: [
      llmstxt({
        domain: 'https://sebscholl-labs.github.io',
        customTemplateVariables: {
          title: 'regexes',
          description: 'Named, tested regular expressions for Ruby: frozen Regexps for UUIDs, IP addresses, ' +
            'ISO 8601 times, IBANs and more, with chainable anchors, repetition and captures, and translation ' +
            'into ECMAScript for JavaScript and JSON Schema.',
          details: llmsDetails,
        },
      }),
    ],
  },
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
          { text: 'For AI Assistants', link: '/guides/ai-instructions' },
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

# frozen_string_literal: true

require 'test_helper'

# Tests for shapes in text: Markdown, template references, file extensions and emoji.
class RegexesTextTest < RegexesTestCase
  WIKIPEDIA_LINK = '[Ruby](https://en.wikipedia.org/wiki/Ruby_(programming_language))'

  cases({
          markdown_code_span:       [['`get_order`', '`a b`', '` `', '`<b>`'], ['``', '`open get_order', 'get_order', '```']],
          markdown_link:            [['[the docs](https://acme.example/docs)', WIKIPEDIA_LINK, '[a](b)', '[a b](/relative/path)'],
                                     ['[a]( b)', '[a](b c)', '[a](b "t")', '[](b)', '[a][1]', '[a]', '(b)', '[a](b', '']],
          ruby_format_reference:    [['%{name}', '%<count>d', '%<price>.2f', '%<n>s', '%<width>-10s', '%{a_1}'],
                                     ['%%{name}', '%{}', '%{1a}', '%<n>', '{name}', '%name', '']],
          mustache_tag:             [['{{name}}', '{{{html}}}', '{{#items}}', '{{/items}}', '{{^empty}}', '{{! note }}', '{{> partial}}',
                                      '{{ user.name }}', '{{&raw}}'],
                                     ['{name}', '{{}}', '{{ }}', '{{{a}}', '{{a}}}', '{{a{b}}', '']],
          shell_variable_reference: [%w[$HOME ${PORT} $_x ${A1}], ['\$HOME', '${PORT:-3000}', '$1', '${}', '$', '', '${HOME HOME}']],
          file_extension:           [%w[.gz .rb .tar .MP4 .7z], ['gz', '.', '.tar.gz', '. gz', '', '.t-z']],
          emoji:                    [%W[\u{1F44D} \u{1F44D}\u{1F3FD} \u{1F468}\u200D\u{1F469}\u200D\u{1F467} \u{1F1E9}\u{1F1EA} 1\uFE0F\u20E3
                                        \u00A9 \u2764\uFE0F \u{1F3F3}\uFE0F\u200D\u{1F308}],
                                     ['a', '1', '#', '', ' ', "\u{1F44D}\u{1F44D}"]]
        }, defined_in: 'text')

  # ── Captures ────────────────────────────────────────────────────────────────────────────────────────────

  test 'a markdown code span captures the code' do
    assert_equal 'get_order', Regexes.markdown_code_span.match('call `get_order` now')[:code]
  end

  test 'a markdown link captures its text' do
    assert_equal 'Ruby', Regexes.markdown_link.match(WIKIPEDIA_LINK)[:text]
  end

  test 'a markdown link captures a destination with parentheses in it' do
    assert_equal 'https://en.wikipedia.org/wiki/Ruby_(programming_language)', Regexes.markdown_link.match(WIKIPEDIA_LINK)[:destination]
  end

  test 'a ruby format reference captures the name in braces' do
    assert_equal 'name', Regexes.ruby_format_reference.match('Hi %{name}')[:name]
  end

  test 'a ruby format reference captures the name in angle brackets' do
    assert_equal 'count', Regexes.ruby_format_reference.match('%<count>d left')[:name]
  end

  test 'ruby format references are found, never an escaped one' do
    assert_equal %w[%{a} %<b>s], found(Regexes.ruby_format_reference, '%{a} %%{x} %<b>s')
  end

  test 'a mustache tag captures its name' do
    assert_equal 'user.name', Regexes.mustache_tag.match('Hi {{ user.name }}')[:name]
  end

  test 'a triple mustache captures its name' do
    assert_equal 'html', Regexes.mustache_tag.match('{{{html}}}')[:name]
  end

  test 'a mustache section captures its sigil' do
    assert_equal '#', Regexes.mustache_tag.match('{{#items}}')[:sigil]
  end

  test 'a plain mustache tag captures no sigil' do
    assert_nil Regexes.mustache_tag.match('{{name}}')[:sigil]
  end

  test 'a shell variable reference captures the name in braces' do
    assert_equal 'PORT', Regexes.shell_variable_reference.match('port ${PORT}')[:name]
  end

  test 'a shell variable reference captures a bare name' do
    assert_equal 'HOME', Regexes.shell_variable_reference.match('cd $HOME')[:name]
  end

  test 'a file extension captures it without the dot' do
    assert_equal 'gz', Regexes.file_extension.trailing.match('backup.tar.gz')[:extension]
  end

  # ── In text ─────────────────────────────────────────────────────────────────────────────────────────────

  test 'a file name without an extension has none at its end' do
    assert_nil 'README'[Regexes.file_extension.trailing]
  end

  test 'emoji are found each whole, with their modifiers and joiners' do
    assert_equal %W[\u{1F44D}\u{1F3FD} \u{1F468}\u200D\u{1F469}\u200D\u{1F467}],
                 "ok \u{1F44D}\u{1F3FD} and \u{1F468}\u200D\u{1F469}\u200D\u{1F467}!".scan(Regexes.emoji)
  end

  test 'a flag is one emoji of two regional indicators' do
    assert_equal %W[\u{1F1E9}\u{1F1EA} \u{1F1EB}\u{1F1F7}], "\u{1F1E9}\u{1F1EA}\u{1F1EB}\u{1F1F7}".scan(Regexes.emoji)
  end

  test 'a plain digit is not an emoji' do
    assert_empty 'room 101'.scan(Regexes.emoji)
  end

  test 'markdown links are found in a paragraph' do
    assert_equal 2, found(Regexes.markdown_link, 'See [a](b) and [c](d).').size
  end
end

# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'open3'

Dir[File.expand_path('../regexes/patterns/*_test.rb', __dir__)].each { require it }

# Every named pattern that translates into ECMAScript, run in Node on every text of its case table: JavaScript
# must reach the same verdict as Ruby on each, whole and in a search.
class RegexesEcmascriptPropertiesTest < RegexesTestCase
  # Reads [{source, flags, texts}] on standard input, writes each text's verdict as JSON.
  SCRIPT = <<~JS
    const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    const verdicts = input.map(({ source, flags, texts }) => {
      const pattern = new RegExp(source, flags);
      return texts.map((text) => pattern.test(text));
    });
    process.stdout.write(JSON.stringify(verdicts));
  JS

  test 'every translated pattern matches whole in JavaScript exactly what it does in Ruby' do
    checks = translated.map { |name, texts| [Regexes.public_send(name).whole, texts] }

    assert_equal ruby_verdicts(checks), node_verdicts(checks)
  end

  test 'every translated pattern finds its first match in JavaScript where Ruby does' do
    checks = translated.map { |name, texts| [Regexes.public_send(name), ["#{AROUND}#{texts.first}#{AROUND}", 'x']] }

    assert_equal ruby_verdicts(checks), node_verdicts(checks)
  end

  private

  # @return [Array<Array(Symbol, Array<String>)>] each named pattern that translates, with every text of its case
  #   table
  def translated
    CASES.filter_map do |name, (matches, refuses)|
      Regexes.public_send(name).ecma_source
      [name, matches + refuses] if matches.any?
    rescue Regexes::UntranslatableError
      nil
    end
  end

  # @param checks [Array<Array(Regexes::Expression, Array<String>)>] patterns, each with texts
  # @return [Array<Hash{String => String}>] each pattern, labelled, with Ruby's verdict on each text
  def ruby_verdicts(checks) = checks.map { |pattern, texts| labelled(pattern, texts.map { pattern.match?(it) }) }

  # @param checks [Array<Array(Regexes::Expression, Array<String>)>] patterns, each with texts
  # @return [Array<Hash{String => String}>] each pattern, labelled, with Node's verdict on each text
  def node_verdicts(checks)
    skip 'Node.js is not installed' unless system('node', '--version', out: File::NULL)

    input           = checks.map { |pattern, texts| { source: pattern.ecma_source, flags: pattern.ecma_flags, texts: } }
    output, status  = Open3.capture2('node', '-e', SCRIPT, stdin_data: JSON.generate(input))
    raise "node failed: #{status}" unless status.success?

    JSON.parse(output).zip(checks).map { |verdicts, (pattern, _)| labelled(pattern, verdicts) }
  end

  # @param pattern [Regexes::Expression] a pattern
  # @param verdicts [Array<Boolean>] its verdict on each text
  # @return [Hash{String => Array<Boolean>}] the verdicts under the pattern's Ruby source, so a difference names it
  def labelled(pattern, verdicts) = { pattern.inspect => verdicts }
end

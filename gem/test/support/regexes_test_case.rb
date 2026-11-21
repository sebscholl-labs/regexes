# frozen_string_literal: true

# The suite's base: Minitest, with tests declared as +test 'what it does' do … end+. The description is the
# test's name as written, so two tests can't share one by differing only in punctuation or spacing.
class RegexesTestCase < Minitest::Test
  # A character no named pattern's first example begins or ends with, placed around one to find it in text.
  AROUND = "\u0001"
  # Every section's case table, by pattern, as each section's test declares it: the texts a suite in
  # test/properties/ checks every pattern against.
  CASES  = {} # rubocop:disable Style/MutableConstant -- filled by each section's test as it loads

  class << self
    # @param description [String] what the test shows
    # @raise [ArgumentError] when another test in the class already has the description
    # @return [Symbol] the test method's name
    def test(description, &)
      name = "test_ #{description}"
      raise ArgumentError, "#{name} is already defined in #{self}" if method_defined?(name)

      define_method(name, &)
    end

    # Declares the tests every named pattern in one section gets from its row in +table+: each text it must
    # match whole and each it must refuse; its first match refused whole with a line after it or a space before
    # it (the +^+/+$+ mistake); its first match found inside other text; and that it is the same frozen
    # expression every time. Then one test that every pattern defined in the section's file has a row.
    #
    # A pattern that ends looking ahead at a character it doesn't take (+folded_line_break+) never matches a
    # text whole; its row has no matches, and its section tests it in text instead. A pattern that must end its
    # line (+markdown_code_block+) is found between line feeds rather than {AROUND}: its row ends with
    # <tt>{ around: "\n" }</tt>.
    #
    # @param table [Hash{Symbol => Array}] each pattern, with the texts it must match whole, the texts it must
    #   refuse whole, and optionally a Hash with +around+, what to find its first match between
    # @param defined_in [String] the section's file, under +lib/regexes/patterns/+, without +.rb+
    # @return [void]
    def cases(table, defined_in:)
      CASES.merge!(table)
      table.each { |name, (matches, refuses, options)| pattern_tests(name, matches, refuses, **options.to_h) }

      test "every pattern defined in patterns/#{defined_in}.rb has cases" do
        assert_equal patterns_defined_in("patterns/#{defined_in}.rb").sort, table.keys.sort
      end
    end

    private

    # @param name [Symbol] a named pattern
    # @param matches [Array<String>] texts it must match whole, the first a typical one
    # @param refuses [Array<String>] texts it must refuse whole
    # @param around [String] what to find its first match between
    # @return [void]
    def pattern_tests(name, matches, refuses, around: AROUND)
      matches.each { |text| test("#{name} matches #{text.inspect} whole") { assert_match pattern(name).whole, text } }
      refuses.each { |text| test("#{name} refuses #{text.inspect} whole") { refute_match pattern(name).whole, text } }
      example_tests(name, matches.first, around) if matches.any?
      object_tests(name)
    end

    # @param name [Symbol] a named pattern
    # @param example [String] a text it matches whole
    # @param around [String] what to find it between
    # @return [void]
    def example_tests(name, example, around)
      test("#{name} whole refuses its first match with a line after it") do
        refute_match pattern(name).whole, "#{example}\n#{AROUND}"
      end
      test("#{name} whole refuses its first match with a space before it") do
        refute_match pattern(name).whole, " #{example}"
      end
      test("#{name} finds its first match inside other text") do
        assert_includes found(pattern(name), "#{around}#{example}#{around}"), example
      end
    end

    # @param name [Symbol] a named pattern
    # @return [void]
    def object_tests(name)
      test("#{name} is an expression") { assert_kind_of Regexes::Expression, pattern(name) }
      test("#{name} is the same object every time") { assert_same pattern(name), pattern(name) }
      test("#{name} is frozen") { assert_predicate pattern(name), :frozen? }
    end
  end

  private

  # @param name [Symbol] a named pattern
  # @return [Regexes::Expression] it
  def pattern(name) = Regexes.public_send(name)

  # @param pattern [Regexp] a pattern
  # @param text [String] text to search
  # @return [Array<String>] every whole match of +pattern+ in +text+, whatever it captures
  def found(pattern, text) = text.to_enum(:scan, pattern).map { Regexp.last_match[0] }

  # @param file [String] the end of a lib file's path, as +patterns/times.rb+
  # @return [Array<Symbol>] the public methods of +Regexes+ defined in that file
  def patterns_defined_in(file)
    Regexes.instance_methods(false).select { Regexes.instance_method(it).source_location.first.end_with?(file) }
  end
end

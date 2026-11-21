# frozen_string_literal: true

# The suite's base: Minitest, with tests declared as +test 'what it does' do … end+. The description is the
# test's name as written, so two tests can't share one by differing only in punctuation or spacing.
class RegexesTestCase < Minitest::Test
  class << self
    # @param description [String] what the test shows
    # @raise [ArgumentError] when another test in the class already has the description
    # @return [Symbol] the test method's name
    def test(description, &)
      name = "test_ #{description}"
      raise ArgumentError, "#{name} is already defined in #{self}" if method_defined?(name)

      define_method(name, &)
    end
  end
end

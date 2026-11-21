# frozen_string_literal: true

require 'minitest/autorun'
require 'regexes'

module Regexes
  # The suite's base: Minitest, with tests declared as +test 'what it does' do … end+.
  class TestCase < Minitest::Test
    class << self
      # @param description [String] what the test shows
      # @raise [ArgumentError] when another test already has the description
      def test(description, &)
        name = "test_ #{description}"
        raise ArgumentError, "#{name} is already defined in #{self}" if method_defined?(name)

        define_method(name, &)
      end
    end
  end
end

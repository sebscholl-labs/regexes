# frozen_string_literal: true

module RuboCop
  module Cop
    module Regexes
      # A test file defines exactly one top-level class, its test class (see `.claude/rules/tests.md`). Helpers
      # and shared setup belong in `test/support/`. Classes and constants nested inside the test class are fine.
      #
      # @example
      #   # bad: test/regexes/expression_test.rb
      #   module Helpers; end
      #   class RegexesExpressionTest < RegexesTestCase; end
      #
      #   # good
      #   class RegexesExpressionTest < RegexesTestCase
      #     TEXTS = %w[a b].freeze
      #   end
      class OneTestClassPerFile < Base
        MSG        = 'Define exactly one top-level class per test file (found %<count>d); ' \
                     'move helpers to test/support/.'
        MSG_MODULE = 'Define the test as a top-level class, not inside a module; move helper modules to test/support/.'

        # @return [void]
        def on_new_investigation
          definitions = top_level_nodes.select { it.class_type? || it.module_type? }
          definitions.select(&:module_type?).each { add_offense(it.loc.keyword, message: MSG_MODULE) }

          check_count(definitions) unless definitions.size == 1
        end

        private

        # @param definitions [Array<RuboCop::AST::Node>] the file's top-level classes and modules, other than one
        # @return [void]
        def check_count(definitions)
          message = format(MSG, count: definitions.size)
          return add_global_offense(message) if definitions.empty?

          definitions.drop(1).each { add_offense(it.loc.keyword, message:) }
        end

        # @return [Array<RuboCop::AST::Node>] the file's top-level statements
        def top_level_nodes
          root = processed_source.ast
          return [] unless root

          root.begin_type? ? root.children : [root]
        end
      end
    end
  end
end

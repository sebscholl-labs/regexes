# frozen_string_literal: true

module RuboCop
  module Cop
    module Regexes
      # Each test makes exactly one top-level assertion (see `.claude/rules/tests.md`).
      #
      # Checks `def test_*` methods, `define_method` blocks and the suite's own `test 'what it does' do` blocks.
      # An assertion is a receiver-less `assert*` / `refute*` / `flunk` call. Calls nested inside an assertion's
      # arguments or block are part of that assertion.
      #
      # @example
      #   # bad
      #   test 'reads the parts' do
      #     assert_equal 'ada', match[:local]
      #     assert_equal 'acme.example', match[:domain]
      #   end
      #
      #   # good
      #   test 'reads the local part' do
      #     assert_equal 'ada', match[:local]
      #   end
      #
      #   test 'reads the domain' do
      #     assert_equal 'acme.example', match[:domain]
      #   end
      class OneAssertionPerTest < Base
        MSG       = 'Make exactly one assertion per test (found %<count>d).'
        ASSERTION = /\A(?:assert|refute)(?:_|\z)|\Aflunk\z/
        MACROS    = %i[define_method test].freeze

        # @param node [RuboCop::AST::DefNode] a method definition
        # @return [void]
        def on_def(node)
          return unless node.method_name.start_with?('test_')

          check(node.loc.name, node.body)
        end

        # @param node [RuboCop::AST::BlockNode] a block
        # @return [void]
        def on_block(node)
          call = node.send_node
          return if call.receiver || !MACROS.include?(call.method_name)

          check(call, node.body)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        # @param range [RuboCop::AST::Node, Parser::Source::Range] where to report
        # @param body [RuboCop::AST::Node, nil] the test's body
        # @return [void]
        def check(range, body)
          count = count_assertions(body)
          return if count == 1

          add_offense(range, message: format(MSG, count:))
        end

        # @param node [RuboCop::AST::Node, Object] a node of the body, or a literal child of one
        # @return [Integer] the top-level assertions in it
        def count_assertions(node)
          return 0 unless node.is_a?(::RuboCop::AST::Node)
          return 1 if assertion?(node)

          node.children.sum { count_assertions(it) }
        end

        # @param node [RuboCop::AST::Node] a node of the body
        # @return [Boolean] whether it is an assertion, with or without a block
        def assertion?(node)
          call = node.any_block_type? ? node.send_node : node

          call.send_type? && call.receiver.nil? && ASSERTION.match?(call.method_name)
        end
      end
    end
  end
end

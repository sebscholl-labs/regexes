# frozen_string_literal: true

module RuboCop
  module Cop
    module Regexes
      # A named pattern follows the naming conventions a machine can check (see `.claude/rules/patterns.md` and
      # `site/design/naming.md`), and has the shape every named pattern has: an endless method, without
      # parameters, returning the constant of the same name.
      #
      # It checks every method defined directly in +module Regexes+ whose body is a constant. Composition
      # (+sequence+, +either+) and other methods with parameters are not named patterns and are left alone.
      #
      # @example
      #   # bad: a variation as a name, and an abbreviation
      #   def non_digits = NON_DIGITS
      #   def ipv4_addr = IPV4_ADDR
      #
      #   # bad: the constant has another name
      #   def uuid = UUID_PATTERN
      #
      #   # good
      #   def digits = DIGITS
      #   def ipv4_address = IPV4_ADDRESS
      class PatternNaming < Base
        MSG_CASE         = 'Name a pattern in snake_case: `%<name>s` is not.'
        MSG_NEGATION     = "Don't name a complement: write `%<rest>s.excluded` instead of `%<name>s`."
        MSG_VARIATION    = "Don't name a variation: `%<word>s` in `%<name>s` is written as a method on the pattern."
        MSG_ABBREVIATION = 'Spell out `%<word>s` in `%<name>s`: only common names (uuid, url, ipv4, iban) stay short.'
        MSG_CONSTANT     = 'Return the constant named after the pattern: `def %<name>s = %<constant>s`.'
        SNAKE_CASE       = /\A[a-z][a-z0-9]*(?:_[a-z0-9]+)*\z/
        NEGATIONS        = %w[non not].freeze
        VARIATIONS       = %w[run runs whole leading trailing excluded optional repeated insensitive].freeze
        ABBREVIATIONS    = %w[addr num str expr re regex rx pat msg char chars ws nl dt ts tz].freeze

        # @param node [RuboCop::AST::DefNode] a method definition
        # @return [void]
        def on_def(node)
          return unless named_pattern?(node)

          name  = node.method_name.to_s
          words = name.split('_')
          return add_offense(node.loc.name, message: format(MSG_CASE, name:)) unless SNAKE_CASE.match?(name)

          check_words(node, name, words)
          check_constant(node, name)
        end

        private

        # @param node [RuboCop::AST::DefNode] a method definition
        # @return [Boolean] whether it defines a named pattern: no parameters, a constant as its whole body, directly
        #   in +module Regexes+
        def named_pattern?(node)
          node.arguments.empty? && node.body&.const_type? && in_regexes?(node)
        end

        # @param node [RuboCop::AST::DefNode] a method definition
        # @return [Boolean] whether the module around it is +Regexes+ itself
        def in_regexes?(node)
          scope = node.each_ancestor(:module, :class).first

          scope&.module_type? && scope.identifier.const_name == 'Regexes'
        end

        # @param node [RuboCop::AST::DefNode] a named pattern
        # @param name [String] its name
        # @param words [Array<String>] its name, split at underscores
        # @return [void]
        def check_words(node, name, words)
          if NEGATIONS.include?(words.first)
            add_offense(node.loc.name, message: format(MSG_NEGATION, rest: words.drop(1).join('_'), name:))
          end

          report_words(node, words & VARIATIONS, MSG_VARIATION, name)
          report_words(node, words & ABBREVIATIONS, MSG_ABBREVIATION, name)
        end

        # @param node [RuboCop::AST::DefNode] a named pattern
        # @param words [Array<String>] the words of its name to report
        # @param message [String] the message, formatted with +word+ and +name+
        # @param name [String] its name
        # @return [void]
        def report_words(node, words, message, name)
          words.each { add_offense(node.loc.name, message: format(message, word: it, name:)) }
        end

        # @param node [RuboCop::AST::DefNode] a named pattern
        # @param name [String] its name
        # @return [void]
        def check_constant(node, name)
          constant = name.upcase
          return if node.endless? && node.body.const_name == constant

          add_offense(node.body, message: format(MSG_CONSTANT, name:, constant:))
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Regexes
      # A test file mirrors the lib file it tests, and its class is named after that file (see
      # `.claude/rules/tests.md`):
      #
      #   test/regexes_test.rb                   -> lib/regexes.rb, RegexesTest
      #   test/regexes/expression_test.rb        -> lib/regexes/expression.rb, RegexesExpressionTest
      #   test/regexes/patterns/times_test.rb    -> lib/regexes/patterns/times.rb, RegexesTimesTest
      #
      # `patterns/` is a folder, not a namespace (its files add methods to `Regexes` itself), so it is left out of
      # the name. Names compare without case or underscores. Directories that don't mirror lib (`test/support`,
      # `test/properties`) are excluded in `.rubocop.yml`.
      class MirroredTestPath < Base
        MSG_NO_LIB          = "%<test>s doesn't mirror a lib file: expected %<lib>s to exist."
        MSG_NAME            = 'Name this test class after %<lib>s: expected `%<expected>s` (case-insensitive).'
        TEST_PATH           = %r{\Atest/(.+)_test\.rb\z}
        NAMESPACE_FREE_DIRS = %w[patterns].freeze

        # @return [void]
        def on_new_investigation
          relative = relative_path
          match    = TEST_PATH.match(relative)
          return unless match

          stem = match[1]
          lib  = "lib/#{stem}.rb"
          return check_name(stem, lib) if File.exist?(File.join(base_dir, lib))

          add_global_offense(format(MSG_NO_LIB, test: relative, lib:))
        end

        private

        # @return [String] the directory paths are relative to: the one holding `.rubocop.yml`
        def base_dir = config.base_dir_for_path_parameters

        # @return [String] the inspected file's path, relative to {#base_dir}
        def relative_path
          File.expand_path(processed_source.file_path.to_s).delete_prefix("#{File.expand_path(base_dir)}/")
        end

        # @param stem [String] the test's path without +test/+ and +_test.rb+
        # @param lib [String] the lib file it mirrors
        # @return [void]
        def check_name(stem, lib)
          node = test_class
          return unless node

          segments = stem.split('/').reject { NAMESPACE_FREE_DIRS.include?(it) }
          expected = "#{segments.map { camelize(it) }.join}Test"
          return if normalize(node.identifier.const_name) == normalize(expected)

          add_offense(node.identifier, message: format(MSG_NAME, lib:, expected:))
        end

        # The class ending in +Test+, else the first class. Extra classes are OneTestClassPerFile's to report.
        #
        # @return [RuboCop::AST::ClassNode, nil]
        def test_class
          classes = top_level_nodes.select(&:class_type?)

          classes.find { it.identifier.short_name.to_s.end_with?('Test') } || classes.first
        end

        # @return [Array<RuboCop::AST::Node>] the file's top-level statements
        def top_level_nodes
          root = processed_source.ast
          return [] unless root

          root.begin_type? ? root.children : [root]
        end

        # @param segment [String] one snake_case segment of a path
        # @return [String] it in CamelCase
        def camelize(segment) = segment.split('_').map(&:capitalize).join

        # @param name [String, Symbol] a constant's name
        # @return [String] it without colons, underscores or case
        def normalize(name) = name.to_s.delete(':_').downcase
      end
    end
  end
end

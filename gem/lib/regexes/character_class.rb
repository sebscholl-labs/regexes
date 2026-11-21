# frozen_string_literal: true

module Regexes
  # A set of characters, matching any one of them, with the variations a set allows beyond an expression's:
  # the characters outside it ({#excluded}) and the set with more characters in it ({#including}).
  #
  # Its members are written as they would be between a regular expression's brackets: +a-z0-9+. A set is one
  # unit, so it is repeated as it is: +[a-z]++.
  class CharacterClass < Expression
    # @return [String] the characters in the set, as written between brackets
    attr_reader :members

    # @param members [String] the characters in the set, as written between brackets
    # @param excluded [Boolean] whether it matches any character but these
    # @param options [Integer] +Regexp+ options, such as +Regexp::IGNORECASE+
    def initialize(members, excluded: false, options: 0)
      @members  = members
      @excluded = excluded
      super("[#{'^' if excluded}#{members}]", single: true, options:)
    end

    # +Regexes.lowercase_letters.excluded+ matches the +1+ and the +A+ of +a1A+. Excluding the excluded set
    # gives back the set.
    #
    # @return [CharacterClass] the set of every character not in this one
    def excluded = CharacterClass.new(members, excluded: !excluded?, options:)

    # +Regexes.lowercase_alphanumeric.including('_')+ matches +a+, +1+ and +_+. An excluded set excludes the
    # added characters too: +Regexes.slash.excluded.including('?')+ matches neither +/+ nor +?+.
    #
    # @param characters [String] more characters, as written between brackets
    # @return [CharacterClass] the set with them
    def including(characters) = CharacterClass.new("#{members}#{characters}", excluded: excluded?, options:)

    # @return [CharacterClass] the set, matching letters of either case
    def case_insensitive = CharacterClass.new(members, excluded: excluded?, options: options | IGNORECASE)

    # @return [Boolean] whether it matches the characters outside its members
    def excluded? = @excluded
  end
end

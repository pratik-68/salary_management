module Analytics
  # The middle value of a set of salaries, or the mean of the two middle ones
  # when there is an even number of them.
  #
  # That is Excel's MEDIAN, which matters: the HR Manager lives in spreadsheets
  # and will check a figure here against one there, so the two have to agree.
  #
  # SQLite has no median function, hence Ruby. The arithmetic is exact — a
  # Rational, not a float — so the caller decides where to round rather than
  # inheriting whatever error a float introduced on the way.
  module Median
    # @param values [Enumerable<Integer>]
    # @return [Integer, Rational, nil] nil for an empty set: no people means no
    #   middle salary, which is not the same as a salary of zero.
    def self.of(values)
      sorted = values.sort
      return nil if sorted.empty?

      middle = sorted.length / 2
      return sorted[middle] if sorted.length.odd?

      Rational(sorted[middle - 1] + sorted[middle], 2)
    end
  end
end

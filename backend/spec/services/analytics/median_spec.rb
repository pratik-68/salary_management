require "rails_helper"

RSpec.describe Analytics::Median do
  describe ".of" do
    # Expected values are worked out by hand, not read off the implementation.
    {
      "an empty set has no middle value" => { values: [], expected: nil },
      "a single value is its own median" => { values: [ 90_000 ], expected: 90_000 },
      "an odd count takes the middle value" => { values: [ 10, 30, 20 ], expected: 20 },
      "an even count takes the mean of the middle two" => { values: [ 10, 20, 30, 40 ], expected: 25 },
      "an even count can land on a half" => { values: [ 1, 2 ], expected: 1.5 },
      "repeated values are not collapsed" => { values: [ 5, 5, 5, 9 ], expected: 5 },
      "the input does not have to be sorted" => { values: [ 200_000, 90_000, 120_000 ], expected: 120_000 }
    }.each do |description, table|
      it description do
        expect(described_class.of(table[:values])).to eq(table[:expected])
      end
    end

    it "is exact rather than floating point, so rounding is the caller's call" do
      expect(described_class.of([ 1, 2 ])).to eq(Rational(3, 2))
    end

    it "leaves the caller's array alone" do
      values = [ 30, 10, 20 ]

      described_class.of(values)

      expect(values).to eq([ 30, 10, 20 ])
    end
  end
end

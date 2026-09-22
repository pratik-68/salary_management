# The JSON shape of a pay breakdown.
#
# This is where the exact figures become numbers to put on a screen. Median and
# average are rounded to whole currency units: a salary is a whole number of
# rupees or euros, so half of one is noise, and Excel's ROUND rounds a half up
# the same way.
#
# Every row carries its own currency, and the meta says whether the whole
# breakdown shares one. Headcount is the only figure summed across rows,
# because it is the only one with no currency attached.
class BreakdownSerializer
  def self.one(breakdown)
    new(breakdown).as_json
  end

  def initialize(breakdown)
    @breakdown = breakdown
  end

  def as_json(*)
    {
      data: breakdown.rows.map { |row| row_json(row) },
      meta: {
        group_by: breakdown.group_by,
        country: breakdown.country_code,
        currency: breakdown.currency,
        headcount: breakdown.headcount
      }
    }
  end

  private

  attr_reader :breakdown

  def row_json(row)
    {
      group: row.group,
      country_code: row.country_code,
      country_name: row.country_name,
      currency: row.currency,
      headcount: row.headcount,
      min: row.min,
      median: row.median&.round,
      average: row.average.round,
      max: row.max,
      total: row.total
    }
  end
end

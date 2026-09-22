# The catalog as the SPA needs it: everything behind the filter bar and the
# employee form in one response, fetched once on load.
#
# Job titles are sent both grouped by department, so the form can narrow the
# title list once a department is picked, and as a flat list, so the filter bar
# can offer titles before any department is chosen.
class ReferenceDataSerializer
  def self.one
    new.as_json
  end

  def as_json(*)
    {
      countries: ReferenceData.countries.map { |country| country.to_h },
      departments: ReferenceData.job_titles_by_department.map do |name, job_titles|
        { name: name, job_titles: job_titles }
      end,
      job_titles: ReferenceData.job_titles,
      levels: ReferenceData.levels
    }
  end
end

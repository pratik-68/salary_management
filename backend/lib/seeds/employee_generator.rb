module Seeds
  # Builds employee attribute hashes for db/seeds.rb.
  #
  # The output is deterministic: the same seed always produces the same people,
  # with the same pay, so a demo, a screenshot and a hand-checked figure all
  # stay true from one run to the next. Everything random comes from the
  # injected RNG — nothing reads the system clock or Kernel#rand.
  #
  # The data is shaped to make the insights worth looking at: headcount is
  # weighted towards a few countries and towards Engineering, and pay is built
  # from a role base, a level multiplier and a per-country scale, so that
  # grouping by department, title or level shows a real spread rather than
  # noise.
  class EmployeeGenerator
    include Enumerable

    DEFAULT_COUNT = 10_000
    DEFAULT_SEED = 20_260_920

    # Hire dates are spread over the ten years ending here. The anchor is fixed
    # rather than Date.current so that the dataset is reproducible on any day;
    # pass `as_of:` to move it.
    REFERENCE_DATE = Date.new(2026, 9, 20)
    YEARS_OF_HISTORY = 10

    # Relative headcount. Not every country or department is the same size, and
    # a flat split would make every breakdown look alike.
    COUNTRY_WEIGHTS = {
      "IN" => 30, "US" => 25, "GB" => 10, "DE" => 10,
      "PL" => 8, "SG" => 6, "AU" => 6, "BR" => 5
    }.freeze

    DEPARTMENT_WEIGHTS = {
      "Engineering" => 40, "Sales" => 15, "Customer Success" => 12,
      "Product" => 10, "Marketing" => 8, "Finance" => 8, "People" => 7
    }.freeze

    # A pyramid: plenty of juniors and mid-levels, few at L6.
    LEVEL_WEIGHTS = {
      "L1" => 18, "L2" => 24, "L3" => 24, "L4" => 18, "L5" => 11, "L6" => 5
    }.freeze

    # Annual pay for a 1.0 role at L3, in each country's own currency. This is
    # only used to generate plausible local numbers; the app itself never
    # converts between currencies and knows nothing about these figures.
    COUNTRY_PAY_SCALE = {
      "IN" => 1_800_000, "US" => 95_000, "GB" => 62_000, "DE" => 68_000,
      "PL" => 160_000, "SG" => 90_000, "AU" => 105_000, "BR" => 130_000
    }.freeze

    # What a title is worth relative to a Software Engineer.
    ROLE_BASE = {
      "Software Engineer" => 1.0, "QA Engineer" => 0.85, "DevOps Engineer" => 1.05,
      "Data Engineer" => 1.05, "Engineering Manager" => 1.25,
      "Product Manager" => 1.1, "Product Designer" => 0.95, "UX Researcher" => 0.9,
      "Account Executive" => 0.95, "Sales Development Representative" => 0.7, "Sales Manager" => 1.15,
      "Marketing Manager" => 1.0, "Content Strategist" => 0.8, "Growth Marketer" => 0.9,
      "Financial Analyst" => 0.85, "Accountant" => 0.8, "Finance Manager" => 1.1,
      "Recruiter" => 0.8, "HR Business Partner" => 0.9, "People Operations Manager" => 1.0,
      "Customer Success Manager" => 0.9, "Support Engineer" => 0.75, "Support Team Lead" => 0.95
    }.freeze

    LEVEL_MULTIPLIER = {
      "L1" => 0.6, "L2" => 0.8, "L3" => 1.0, "L4" => 1.3, "L5" => 1.65, "L6" => 2.1
    }.freeze

    # Two people in the same role at the same level are not paid identically.
    SALARY_NOISE = 0.15
    # Salaries are negotiated in round numbers, so round to the nearest 1,000.
    SALARY_ROUNDING = -3

    # How many employees this generator yields. Public so that `count` answers
    # without enumerating, and so it does not shadow Enumerable#count.
    attr_reader :count

    def initialize(count: DEFAULT_COUNT, seed: DEFAULT_SEED, as_of: REFERENCE_DATE)
      @count = count
      @seed = seed
      @as_of = as_of
    end

    # Yields one attribute hash per employee, ready for insert_all.
    #
    # The RNG is rebuilt here rather than in the constructor so that enumerating
    # twice gives the same people both times.
    def each
      return enum_for(:each) { count } unless block_given?

      rng = Random.new(seed)
      Faker::Config.random = Random.new(rng.rand(2**32))

      1.upto(count) { |number| yield build(number, rng) }
    end

    private

    attr_reader :seed, :as_of

    def build(number, rng)
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      country_code = weighted_pick(COUNTRY_WEIGHTS, rng)
      department = weighted_pick(DEPARTMENT_WEIGHTS, rng)
      job_title = ReferenceData.job_titles_for(department).sample(random: rng)
      level = weighted_pick(LEVEL_WEIGHTS, rng)

      {
        employee_code: format("EMP-%05d", number),
        first_name: first_name,
        last_name: last_name,
        email: email_for(first_name, last_name, number),
        country_code: country_code,
        department: department,
        job_title: job_title,
        level: level,
        annual_salary: salary_for(country_code, job_title, level, rng),
        hire_date: hire_date(rng)
      }
    end

    # role base x level multiplier x local pay scale, give or take 15%.
    def salary_for(country_code, job_title, level, rng)
      base = COUNTRY_PAY_SCALE.fetch(country_code) *
        ROLE_BASE.fetch(job_title) *
        LEVEL_MULTIPLIER.fetch(level)

      (base * (1 + rng.rand(-SALARY_NOISE..SALARY_NOISE))).round(SALARY_ROUNDING)
    end

    def hire_date(rng)
      as_of - rng.rand(0..(YEARS_OF_HISTORY * 365))
    end

    # The sequence number keeps the address unique even when two people share a
    # name, which happens often at 10,000 rows.
    def email_for(first_name, last_name, number)
      handle = I18n.transliterate("#{first_name}.#{last_name}").downcase.gsub(/[^a-z.]/, "")

      "#{handle}.#{number}@example.com"
    end

    def weighted_pick(weights, rng)
      roll = rng.rand(weights.values.sum)
      cumulative = 0

      weights.each do |value, weight|
        cumulative += weight
        return value if roll < cumulative
      end
    end
  end
end

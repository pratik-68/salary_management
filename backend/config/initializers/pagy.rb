require "pagy/extras/overflow"

# A page size the HR Manager can actually read. The controller caps what a
# request may ask for, so no single call can pull all 10,000 rows.
Pagy::DEFAULT[:limit] = 25

# A page past the end comes back empty rather than raising: the total in the
# meta still says where the data stops, and a stale bookmark on page 400 should
# not be a 500.
Pagy::DEFAULT[:overflow] = :empty_page

Pagy::DEFAULT.freeze

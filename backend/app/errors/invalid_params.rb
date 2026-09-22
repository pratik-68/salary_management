# Raised when a request asks for something the API cannot answer: an unknown
# sort column, a filter value that is not in the catalog, a salary sort with no
# country to anchor it.
#
# These are mistakes in the request rather than a record failing validation, so
# they come back as 400 with a stable code the SPA can branch on, not as a 422
# with per-field messages.
class InvalidParams < StandardError
  DEFAULT_CODE = "invalid_params".freeze

  attr_reader :code

  def initialize(message, code: DEFAULT_CODE)
    @code = code
    super(message)
  end
end

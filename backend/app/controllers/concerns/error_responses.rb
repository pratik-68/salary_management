# One JSON shape for every error the API returns:
#
#   { "error": { "code": "not_found", "message": "..." } }
#
# so the SPA can branch on a stable code rather than parsing prose. Validation
# failures are the exception: they carry per-field messages and use
# { "errors": { "field": ["..."] } } instead, because the form needs to put
# each message next to the input that caused it.
module ErrorResponses
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from InvalidParams, with: :render_invalid_params
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  end

  private

  def render_error(status, code:, message:)
    render json: { error: { code: code, message: message } }, status: status
  end

  def render_not_found(_error = nil)
    render_error(:not_found, code: "not_found", message: "We couldn't find what you asked for.")
  end

  # A request we can't make sense of: an unknown sort column, a filter value
  # that isn't in the catalog. The filter raises these rather than quietly
  # ignoring the parameter.
  def render_invalid_params(error)
    render_error(:bad_request, code: error.code, message: error.message)
  end

  def render_parameter_missing(error)
    render_error(:bad_request, code: "invalid_params", message: "Missing required parameter: #{error.param}.")
  end

  def render_invalid(record)
    render json: { errors: record.errors.to_hash(true) }, status: :unprocessable_content
  end
end

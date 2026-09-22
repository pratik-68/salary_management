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
  end

  private

  def render_error(status, code:, message:)
    render json: { error: { code: code, message: message } }, status: status
  end

  def render_not_found(_error = nil)
    render_error(:not_found, code: "not_found", message: "We couldn't find what you asked for.")
  end

  def render_invalid(record)
    render json: { errors: record.errors.to_hash(true) }, status: :unprocessable_content
  end
end

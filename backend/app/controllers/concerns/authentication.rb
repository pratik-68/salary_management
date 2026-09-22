# Sign-in is required by default: every controller inheriting from
# ApplicationController demands a session unless it opts out with
# allow_unauthenticated_access. Protecting endpoints is therefore the default
# rather than something each new controller has to remember.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  # The cookie holds a session record id, signed so it cannot be forged. The
  # session lives in the database, so signing out or revoking access takes
  # effect immediately rather than waiting for a token to expire.
  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  # No redirect to a login page: this is a JSON API, so an unauthenticated
  # request gets a 401 and the SPA decides where to send the user.
  def request_authentication
    render_error(:unauthorized, code: "unauthorized", message: "You must sign in to do that.")
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = {
        value: session.id,
        httponly: true,          # unreadable from JavaScript, so XSS cannot steal it
        same_site: :lax,         # not sent cross-site, which is what stands in for a CSRF token here
        secure: Rails.env.production?
      }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end

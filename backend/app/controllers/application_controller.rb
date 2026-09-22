class ApplicationController < ActionController::API
  # Cookies are not part of ActionController::API by default; the session
  # cookie added back in config/application.rb needs this.
  include ActionController::Cookies
  include ErrorResponses
  include Authentication
end

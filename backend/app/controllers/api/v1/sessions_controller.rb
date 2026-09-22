module Api
  module V1
    class SessionsController < ApplicationController
      allow_unauthenticated_access only: :create

      # Signing in is the one endpoint an attacker can guess at, so it is the
      # one that is rate limited. Ten attempts per IP per three minutes is well
      # clear of a person mistyping a password.
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rate_limited }

      # The SPA calls this on load to find out whether it is already signed in.
      # Not signed in is a 401 like anywhere else, not an empty 200.
      def show
        render json: { data: UserSerializer.one(Current.user) }
      end

      def create
        user = User.authenticate_by(credentials)

        if user
          start_new_session_for(user)
          render json: { data: UserSerializer.one(user) }, status: :created
        else
          # Deliberately vague: saying which of the two was wrong would tell an
          # attacker which email addresses exist.
          render_error(:unauthorized, code: "invalid_credentials", message: "Try another email address or password.")
        end
      end

      def destroy
        terminate_session
        head :no_content
      end

      private

      def credentials
        params.permit(:email_address, :password)
      end

      def render_rate_limited
        render_error(:too_many_requests, code: "too_many_requests", message: "Too many sign-in attempts. Try again later.")
      end
    end
  end
end

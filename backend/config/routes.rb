Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # A singular resource: there is only ever the current user's session.
      #   GET    /api/v1/session  -> who am I (401 if nobody)
      #   POST   /api/v1/session  -> sign in
      #   DELETE /api/v1/session  -> sign out
      resource :session, only: %i[show create destroy]

      # No destroy: someone leaving should be recorded, not erased. See the
      # exclusions in docs/REQUIREMENTS.md.
      resources :employees, only: %i[index show create update]

      # The reference-data catalog behind the dropdowns.
      resource :meta, only: :show
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

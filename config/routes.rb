Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :employees, only: %i[index show create update destroy] do
        resources :salary_changes, only: :index
      end
      resource :meta, only: :show, controller: :meta

      scope :insights, controller: :insights, as: :insights do
        get :summary
        get :by_country
        get :by_job_title
        get :by_department
        get :distribution
      end
    end
  end

  # React app: everything that isn't the API, a static file or the health check.
  root "frontend#index"
  get "*path", to: "frontend#index", constraints: ->(request) { !request.path.start_with?("/api/") && request.format.html? }
end

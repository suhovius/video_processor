Rails.application.routes.draw do
  Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        resources :users, only: :create
        resources :video_processing_infos, only: [:index, :create] do
          member do
            patch "restart"
          end
        end
      end
    end
  end
end

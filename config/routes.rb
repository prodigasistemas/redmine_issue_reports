RedmineApp::Application.routes.draw do
  resources :projects do
    resources :issue_reports, only: [:index, :create]
  end
end

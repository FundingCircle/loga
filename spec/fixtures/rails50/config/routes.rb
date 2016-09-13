Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'ok'        => 'application#ok'
  get 'error'     => 'application#error'
  get 'show'      => 'application#show'
  post 'users'    => 'application#create'
  get 'new'       => 'application#new'
  put 'users/:id' => 'application#update'
end

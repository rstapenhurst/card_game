Rails.application.routes.draw do
  resources :player_attributes

  resources :supplies

  resources :piles

  resources :card_piles

  resources :games

	post '/games/:id/add_player' => 'games#add_player'
	post '/games/:id/play_card' => 'games#play_card'
	post '/games/:id/advance_phase' => 'games#advance_phase'
	post '/games/:id/buy_card' => 'games#buy_card'
	get '/game_stream/:id' => 'games#stream'

  resources :players

  resources :users

  resources :cards

  resources :card_attributes

  resources :card_templates

	get '' => 'home#main'
	post '/login' => 'home#login'
	post '/logout' => 'home#logout'
	get '/play/:id' => 'home#play'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

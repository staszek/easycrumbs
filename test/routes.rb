module EasyCrumbs
  class Application < ::Rails::Application
  end
end

EasyCrumbs::Application.routes.draw do
	resources :countries do
		resources :movies do
		  resources :actors
		end
	end	
end

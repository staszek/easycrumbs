ActionController::Routing::Routes.draw do |map|
	
	map.resources :countries do |country|
		country.resources :movies do |movie|
		  movie.resources :actors
		end
	end	
	
end
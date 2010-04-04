module EasyCrumbs
  class Collection
    attr_reader :breadcrumbs, :route, :path
    
    def initialize(options = {})
      @route = find_route
      @path = find_path
      @controller = @path[:controller]
      @action = @path[:action]
      
      @pathes = make_pathes
      @breadcrumbs = make_breadcrumbs(options)
    end
    
    # Finding route with given path and method
    # Return ActionController:Routing::Route object
    def find_route
      routes = ActionController::Routing::Routes.routes.select do |route|
        route.recognize(request_path, :method => request_method) != nil
      end
      raise EasyCrumbs::NotRecognized if routes.empty?
      routes.first
    end
    
    # Return hash with path parameter
    # for example:
    # { :controller => 'movies', :action => 'show', :country_id => '23', :id => '12' }
    def find_path
      @route.recognize(request_path, :method => request_method)
    end
    
    # Select only static and dynamic segments form route. Static segments points at controllers and dynamic points at models. 
    # It is given in right order
    def segments
      @route.segments.select do |segment|
        [ActionController::Routing::DynamicSegment, ActionController::Routing::StaticSegment].include? segment.class
      end
    end
    
    # Returning controller object from static segment
    def pick_controller(segment)
      "#{segment.value.titlecase}Controller".constantize.new
    end
    
    # Retrung model object form dynamic segment
    # If key has not model name then it is taken from current controller(it is taken from path)
    def pick_model(segment)
      key = segment.key
      if key == :id
        model = @controller.singularize
      else
        model = key.to_s[0..-4]  # model_id without last 3 signs = model
      end
      model = model.titlecase.constantize
      model.find(@path[key])
    end
    
    # Retruning array of controllers and models objects from right segments
    # for example
    # [#<CountriesController:0x001>, #<Country:0x001 @name="usa">, #<MoviesController:0x001>, #<Movie:0x001 @name="titanic">]
    def objects
      segments.map do |segment|
        if segment.is_a? ActionController::Routing::DynamicSegment
          pick_model(segment)
        else
          pick_controller(segment)
        end
      end
    end
    
    # Return array of breadcrumbs object in right order
    def make_breadcrumbs(options = {})
      breadcrumbs = [Breadcrumb.new(ApplicationController.new)]
      objects.each_with_index do |object, index|
        options.merge!({:action => @action}) if index == objects.size - 1
        options.merge!({:path => @pathes[index]})
        breadcrumbs << Breadcrumb.new(object, options)
      end
      breadcrumbs
    end
    
    # Retrurn parameters for path of model
    # If it is last object then action is equal to request action
    def path_for_model(segment)
      key = segment.key
      if key == :id
        {:action => @action, :id => @path[key]}
      else
        {:action => 'show', key => @path[key]}
      end
    end
    
    # Retrun parameters for path of controller
    def path_for_controller(segment)
      {:action => 'index', :controller => segment.value}
    end
    
    # If controller name is connected with object then parameter should be :id instead of :object_id
    # {:controller => 'movies', :movie_id => 1} will be {:controller => 'movies', :id => 1}
    def repaired_model_path(path)
      path = path.dup
      object_param = "#{path[:controller].singularize}_id".to_sym
      id = path.delete(object_param)
      id.nil? ? path : path.merge({:id => id})
    end
    
    # Retrun array of pathes for every segment
    # for example:
    # countries > 1 > movies > 2 > actors> 3
    # 
    # {:action => 'index', :controller => 'countries'},
    # {:action => 'show', :controller => 'countries', :id => 1},
    # {:action => 'index', :controller => 'movies', :country_id => 1},
    # {:action => 'show', :controller => 'movies', :country_id => 1, :id => 2},
    # {:action => 'index', :controller => 'actors', :country_id => 1, :movie_id => 2},
    # {:action => 'update', :controller => 'actors', :country_id => 1, :movie_id => 2, :id => 3}
    def make_pathes
      path = {}
      segments.map do |segment|
        if segment.is_a? ActionController::Routing::DynamicSegment
          path.merge! path_for_model(segment)
          result = repaired_model_path(path)
        else
          result = path.merge! path_for_controller(segment)
        end
        result.dup
      end
    end
    
    private
    
    def request_path
    end
    
    def request_method
    end
  end
end
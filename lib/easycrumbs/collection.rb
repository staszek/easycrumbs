module EasyCrumbs
  class Collection
    attr_reader :breadcrumbs, :route, :path
    
    def initialize
      @route = find_route
      @path = find_path
      @controller = @path[:controller]
      @action = @path[:action]
      @breadcrumbs = make_breadcrumbs
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
    
    def objects
      segments.map do |segment|
        if segment.is_a? ActionController::Routing::DynamicSegment
          pick_model(segment)
        else
          pick_controller(segment)
        end
      end
    end
    
    def make_breadcrumbs
      objects.map do |object|
        Breadcrumb.new(object)
      end
    end
    
    private
    
    def request_path
    end
    
    def request_method
    end
  end
end
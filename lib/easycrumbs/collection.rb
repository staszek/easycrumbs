module EasyCrumbs
  class Collection
    attr_reader :breadcrumbs
    
    def initialize
      @breadcrumbs = []
    end
    
    def find_route
      routes = ActionController::Routing::Routes.routes.select do |route|
        route.recognize(path, :method => method) != nil
      end
      raise EasyCrumbs::NotRecognized if routes.empty?
      routes.first
    end
    
    private
    
    def path
    end
    
    def method
    end
  end
end
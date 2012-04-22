module EasyCrumbs
  class Collection
    attr_reader :breadcrumbs, :route, :path

    def initialize(request, options = {})
      @request = request

      @route = find_route
      @path = find_path
      @controller = @path[:controller]
      @action = @path[:action]

      @pathes = make_pathes
      @breadcrumbs = make_breadcrumbs(options)
    end

    # Finding route with given path and method
    # Return ActionController:Routing::Route object
    def find_route(request = @request)
      routes = Rails.application.routes.router.send(:find_routes, request.env)
      raise EasyCrumbs::NotRecognized if routes.empty?
      routes.first
    end

    # Return hash with path parameter
    # for example:
    # { :controller => 'movies', :action => 'show', :country_id => '23', :id => '12' }
    def find_path
      #@route.recognize(request_path, :method => request_method)
      @route.second
    end

    # Select only static and dynamic segments from route. Static segments points at controllers and dynamic points at models.
    # It is given in right order
    # If last segment is equal to member action then it should be deleted. for example movies/123/edit should not return "edit" segment
    def segments
      #segments = @route.segments.select do |segment|
      #  [ActionController::Routing::DynamicSegment, ActionController::Routing::StaticSegment].include? segment.class
      #end
      #segments.pop if segments.last.is_a?(ActionController::Routing::StaticSegment) && segments.last.value == @action && segments.last.value != 'new'
      #segments
      resolve_segments
    end

    # Return array of dynamic segments
    # for example
    # [ :country_id, :dynamic], [:movie_id, :dynamic], [:id, :dynamic] ]
    def dynamic_segments
      @route.third.path.names.map do |segment|
        [segment.to_sym, :dynamic]
      end
    end

    # Return array of all segments with :static and :dynamic annotation
    # for examle:
    # [[:countries, :static], [:country_id, :dynamic], [:movies, :static], [:movie_id, :dynamic], [:actors, :static] ]
    def resolve_segments
      @route.third.path.spec.to_s.split(/[\/(\)\.]/).map do |segment|
        [segment.delete(":").to_sym, :static] unless segment.blank?
      end.compact.map do |segment|
        if dynamic_segments.map(&:first).include? segment.first
          [segment.first, :dynamic]
        else
          segment
        end
      end
    end

    # Returning controller object from static segment
    def pick_controller(segment)
      #segment = last_controller_segment if segment.value == "new"
      #"#{segment.value.titlecase}Controller".constantize.new
      segment = last_controller_segment if segment.first == :new
      "#{segment.first.to_s.titlecase}Controller".constantize.new rescue nil
    end

    # Returns last controller segment in segments
    def last_controller_segment
      #segments.select{ |seg| seg.is_a?(ActionController::Routing::StaticSegment) && seg.value != "new"}.last
      segments.select{ |seg| seg.second == :static && seg.first != :new }.last
    end

    # Retrung model object from dynamic segment
    # If key has not model name then it is taken from current controller(it is taken from path)
    def pick_model(segment)
      key = segment.first
      if key == :id
        model = @controller.singularize
      elsif key.to_s.include?("_id")
        model = key.to_s[0..-4]  # model_id without last 3 signs = model
      else
        return nil
      end

      model = model.titlecase.constantize
      model.find(@path[key])
    end

    # Retruning array of controllers and models objects from right segments
    # for example
    # [#<CountriesController:0x001>, #<Country:0x001 @name="usa">, #<MoviesController:0x001>, #<Movie:0x001 @name="titanic">]
    def objects
      segments.map do |segment|
        if segment.second == :dynamic
          pick_model(segment)
        else
          pick_controller(segment)
        end
      end.compact
    end

    # Return array of breadcrumbs object in right order
    def make_breadcrumbs(options = {})
      breadcrumbs = [Breadcrumb.new(ApplicationController.new, options)]
      objects.each_with_index do |object, index|
        options.merge!({:action => @action}) if index == objects.size - 1
        options.merge!({:path => @pathes[index]})
        breadcrumbs << Breadcrumb.new(object, options)
      end
      breadcrumbs
    end

    # Retrurn parameters for path of model
    # If it is last object then action is equal to request action
    #def path_for_model(segment)
    #  key = segment.value
    #  if key == :id
    #    {:action => @action, :id => @path[key]}
    #  else
    #    {:action => 'show', key => @path[key]}
    #  end
    #end

    # Retrun parameters for path of controller
    #def path_for_controller(segment)
    #  if segment.value == "new"
    #    {:action => "new", :controller => last_controller_segment.value}
    #  else
    #    {:action => 'index', :controller => segment.value}
    #  end
    #end

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
      result = []
      begin
        @route.first.to_s.split("/")[1...-1].inject([]) do |current_path, segment|
          current_path << segment
          request = ActionDispatch::Request.new("PATH_INFO"  => "/#{current_path.join("/")}","REQUEST_METHOD"  => "GET")
          result << (find_route(request).second rescue nil)
          current_path
        end
        (result << @route.second).compact
      rescue nil
      rescue Exception => e
        Rails.logger.debug "Easycrumbs make_pathes exception: #{e.message}\n#{e.inspect}"
      end
    end

    def render(options = {})
      options[:separator] ||= " > "
      options[:last_link] = true if options[:last_link].nil?

      elements = @breadcrumbs.map do |breadcrumb|
        if options[:last_link] == false && breadcrumb == @breadcrumbs.last
          breadcrumb.name
        else
          link_to breadcrumb.name, breadcrumb.path
        end
      end
      elements.join(options[:separator])
    end
    private

    def request_path
      @request.path
    end

    def request_method
      @request.method
    end

    def link_to(name, path)
      "<a href=\"#{path}\">#{name}</a>"
    end
  end
end

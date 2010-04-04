module EasyCrumbs
  class InvalidObject < StandardError
    def message
      "object should be Controller(ActionController::Base) or Model(ActiveRecord::Base)"
    end
  end
  
  class NoName < StandardError
    def initialize(object_class, column)
      @object_class = object_class
      @column = column
    end
    
    def message
      "Can not set name. Model #{@object_class} does not have column \"#{@column}\". Try change column name or create \"#{@column}\" method"
    end
  end
  
  class NoPath < StandardError
    def initialize(routing_error)
      @routing_error = routing_error
    end
    
    def message
      "Can not set path. You can use :blank_links to return nil for no-recognized pathes. RoutingError: #{@routing_error}"
    end
  end
  
  class NotRecognized < StandardError    
    def message
      "Can not recognize main path."
    end
  end
end
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
end
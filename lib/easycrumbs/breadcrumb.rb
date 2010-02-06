module EasyCrumbs
  class Breadcrumb
    attr_reader :object, :name, :path
    
    # Breadcrumb object:
    # object  -   just object from application. Could be a model or controller
    # name    -   printed name
    # path    -   path to this object
    def initialize(object, options = {})      
      @object = set_object(object)
      @name = set_name(options)
      # @path = set_path(object)
    end
    
    
    # Object from application must be a model or controller
    def set_object(object)
      raise EasyCrumbs::InvalidObject unless object.is_a?(ActionController::Base) || object.is_a?(ActiveRecord::Base)
      object
    end
    
    # Set name for model or controller
    def set_name(options = {})
      if object.is_a?(ActiveRecord::Base)
        options[:name_column] ||= "breadcrumb"
        options[:prefix] ||= [:new, :edit]
        name_for_model(options[:name_column], options[:action], options[:prefix])
      else
        #name_for_controller
      end
    end
    
    # Set name for model
    # Model has to have column equal to name_column
    def name_for_model(name_column, action, prefix)
      raise EasyCrumbs::NoName.new(@object.class, name_column) unless @object.respond_to? name_column
      name = @object.send name_column
      add_prefix(name, action, prefix)
    end
    
    # Add specyfic prefix if action is passed
    # prefix =
    # :every               -  add prefix for every action
    # :none                -  do not add prefix
    # [array of symbols]   -  add prefix only for actions in array
    #
    # Example
    # [:show, :new]        -  add prefix only for show and new
    def add_prefix(model_name, action, prefix)
      name = model_name
      unless action.nil?
        prefix = case prefix
          when :every
            [action.to_sym]
          when :none
            []
          else
            prefix
        end
        name = "#{action.titlecase} #{name}" if prefix.include?(action.to_sym)
      end
      name
    end
    
  end
end
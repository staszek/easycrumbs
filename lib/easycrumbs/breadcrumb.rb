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
      @path = set_path(options[:path], options[:blank_links])
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
        name = name_for_model(options[:name_column], options[:i18n])
      else
        name = name_for_controller(options[:i18n])
      end
      add_prefix(name, options[:action], options[:prefix], options[:i18n])
    end

    # Set name for model
    # Model has to have column equal to name_column
    def name_for_model(name_column, i18n)
      if @object.respond_to? name_column
        @object.send name_column
      else
        i18n == true ? I18n.t("breadcrumbs.models.#{object.class.to_s.downcase}") : default_model_name
      end
    end

    # Set name for controller
    def name_for_controller(i18n)
      if @object.respond_to? :breadcrumb
        @object.breadcrumb
      else
        i18n == true ? I18n.t("breadcrumbs.controllers.#{@object.controller_name}") : default_controller_name
      end
    end

    #Return default name for model object
    def default_model_name
      @object.class.to_s
    end

    # Return default name for controller object
    def default_controller_name
      @object.class == ApplicationController ? "Home" : @object.controller_name.titlecase
    end

    # Add specyfic prefix if action is passed
    # prefix =
    # :every               -  add prefix for every action
    # :none                -  do not add prefix
    # [array of symbols]   -  add prefix only for actions in array
    #
    # Example
    # [:show, :new]        -  add prefix only for show and new
    def add_prefix(object_name, action, prefix, i18n)
      name = object_name
      unless action.nil?
        prefix = case prefix
          when :every
            [action.to_sym]
          when :none
            []
          else
            prefix || [:new, :edit]
        end
        name = action_name(action, i18n, name) if prefix.include?(action.to_sym)
      end
      name
    end

    # Return name of action.
    def action_name(action, i18n, name)
      i18n == true ? I18n.t("breadcrumbs.actions.#{action}", :name => name) : "#{action.titlecase} #{name}"
    end

    # Set path using hash from Rails.application.routes.recognize_path
    # Example looks like:
    # {:country_id => "1", :movie_id => "1", :id => "1", :action => "show", :controller => "movies"}
    def set_path(path, blank_links)
      path.nil? || path.empty? ? "/" : Rails.application.routes.generate_extras(path).first
      rescue ActionController::RoutingError => e
        raise EasyCrumbs::NoPath.new(e.message) unless blank_links == true
        nil
    end

  end
end

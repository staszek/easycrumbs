module ActionView
  class Base
    def show_breadcrumbs(options = {})
      EasyCrumbs::Collection.new(request, options).breadcrumbs
    end
  end
end
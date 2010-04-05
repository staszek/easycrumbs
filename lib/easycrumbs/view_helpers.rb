module ActionView
  class Base
    def breadcrumbs(options = {})
      EasyCrumbs::Collection.new(request, options).render(options)
    end
  end
end
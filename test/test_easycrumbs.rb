require 'helper'

class TestEasycrumbs < Test::Unit::TestCase
  context "EasyCrumbs tests" do
    setup do
      @usa = Country.create(:name => "USA", :breadcrumb => "United States of America")
      @titanic = @usa.movies.create(:name => "Titanic")
      @leo = @titanic.actors.create(:first_name => "Leonardo", :last_name => "Di Caprio")
    end

    context "Models testing" do
      should "Leo play in  Titanic" do
        assert_equal(@titanic, @leo.movie)
      end

      should "Titanic be produced in Usa" do
        assert_equal(@usa, @titanic.country)
      end
    end

    context "Breadcrumb model" do
      context "set object" do
        should "model object be ok" do
          assert_equal(@usa, Breadcrumb.new(@usa).object)
        end

        should "controller object be ok" do
          @controller = MoviesController.new
          assert_equal(@controller, Breadcrumb.new(@controller).object)
        end

        should "raise exception for String object" do
          assert_raise(InvalidObject) { Breadcrumb.new("Some string") }
        end
      end

      context "set name" do
        context "for model" do
          should "return breadcrumb column by default if it has breadcrumb column" do
            assert_equal("United States of America", Breadcrumb.new(@usa).name)
          end

          should "return name column if someone set it" do
            assert_equal(@titanic.name, Breadcrumb.new(@titanic, :name_column => "name").name)
          end

          should "return specyfic name using breadcrumb method" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo).name)
          end

          should "return model name if it not respond to name_column method and i18n is turned off" do
            assert_equal("Movie", Breadcrumb.new(Movie.new).name)
          end

          should "return model name from i18n if it not respond to name_column method and i18n is turned on" do
            I18n.expects(:t).with("breadcrumbs.models.movie").returns("Das film")
            assert_equal("Das film", Breadcrumb.new(Movie.new, :i18n => true).name)
          end
        end

        context "for controller" do
          should "return controller name" do
            assert_equal("Movies", Breadcrumb.new(MoviesController.new).name)
          end

          should "return Home for ApplicationController" do
            assert_equal("Home", Breadcrumb.new(ApplicationController.new).name)
          end

          should "return breadcrumb method from controller" do
            assert_equal("Countries list", Breadcrumb.new(CountriesController.new).name)
          end

          should "return transalted name for controller when i18n is turned on" do
            I18n.expects(:t).with("breadcrumbs.controllers.movies").returns("la movies")
            assert_equal("la movies", Breadcrumb.new(MoviesController.new, :i18n => true).name)
          end
        end

        context "with prefix option" do
          should "return name with prefix if action is passed by parameter and it is one of defaults(new or edit)" do
            assert_equal("Edit Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "edit").name)
          end

          should "return only name if it is set to :none" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "edit", :prefix => :none).name)
          end

          should "return prefix and name for every action if it is set to :every" do
            assert_equal("Show Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "show", :prefix => :every).name)
          end

          should "return prefix and name if action is in prefix array" do
            assert_equal("Destroy Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "destroy", :prefix => [:destroy, :edit]).name)
          end

          should "return only name if action is not in prefix array" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "show", :prefix => [:destroy, :edit]).name)
          end

          should "return transalted action as a prefix when i18n is turned on" do
            name = "Leonardo Di Caprio"
            I18n.expects(:t).with("breadcrumbs.actions.edit", {:name => name}).returns("Editzione #{name}")
            assert_equal("Editzione Leonardo Di Caprio", Breadcrumb.new(@leo, :i18n => true, :action => "edit").name)
          end
        end

        context "set path" do
          should "return path if it exist" do
            assert_equal("/countries/1/movies/1/actors/1", Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "show", :controller => "actors"}).path)
          end

          should "raise RoutingError when can not find path" do
            assert_raise(EasyCrumbs::NoPath) { Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "no_action", :controller => "actors"}) }
          end

          should "retrun nil when can not find path and blank_links is on" do
            assert_equal(nil, Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "no_action", :controller => "actors"}, :blank_links => true).path)
          end

          should "return root path for empty path" do
            assert_equal("/", Breadcrumb.new(@leo, :path => {}).path)
          end

          should "return root path for nil path" do
            assert_equal("/", Breadcrumb.new(@leo).path)
          end
        end
      end
    end

    context "Collection" do
      setup do
        Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors/#{@leo.id}", :request_method => :put)
        @collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors/#{@leo.id}", :put))
      end

      context "finding route" do
        should "return route if it can find it" do
          assert_equal(Journey::Route, @collection.route.third.class)
        end

        should "raise error when it can not find route" do
          assert_raise(EasyCrumbs::NotRecognized) do
            @collection = Collection.new(stub_request("/countres/1/videos/"))
            @collection.find_route
          end
        end
      end

      context "find path" do
        should "retrun path hash" do
          assert_equal({:action => "update", :controller => "actors", :country_id => @usa.id.to_s, :movie_id => @titanic.id.to_s, :id => @leo.id.to_s}, @collection.path)
        end
      end

      context "selecting right segments" do
        should "select only static and dynamic segments" do
          results = @collection.segments
          results = results.map(&:second).uniq
          results.delete(:static)
          results.delete(:dynamic)
          assert_equal(true, results.empty?)
        end

        should "return proper segments for member action" do
          #Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors/#{@leo.id}/edit", :request_method => :get)
          collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors/#{@leo.id}/edit", :get))
          assert_equal(8, collection.segments.size)
        end

        should "return proper segments for new action" do
          #Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :request_method => :get)
          collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :get))
          assert_equal(7, collection.segments.size)
        end
      end

      context "pick_controller" do
        should "return controller object" do
          assert_equal(MoviesController, @collection.pick_controller([:movies, :static]).class)
        end

        should "return controller object if action is new" do
          assert_equal(ActorsController, @collection.pick_controller([:new, :static]).class)
        end
      end

      context "last controller" do
        should "return last controller object if last segment is dynamic" do
          assert_equal(:actors, @collection.last_controller_segment.first)
        end

        should "return last controller object if last segment is static" do
          #Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors", :request_method => :get)
          collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors", :get))
          assert_equal(:actors, collection.last_controller_segment.first)
        end

        should "return last controller object if last segment is new action" do
          #Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :request_method => :get)
          collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :get))
          assert_equal(:actors, collection.last_controller_segment.first)
        end
      end

      context "pick_model" do
        should "return model object when key has model name" do
          #segment = ActionController::Routing::DynamicSegment.new(:movie_id)
          segment = [:movie_id, :dynamic]
          assert_equal(@titanic, @collection.pick_model(segment))
        end

        should "return model object when key has not model name"do
          #segment = ActionController::Routing::DynamicSegment.new(:id)
          segment = [:id, :dynamic]
          assert_equal(@leo, @collection.pick_model(segment))
        end
      end

      context "objects" do
        should "change segments into objects" do
          assert_equal([CountriesController, Country, MoviesController, Movie, ActorsController, Actor], @collection.objects.map(&:class))
        end
      end

      #context "path_for_model" do
      #  should "return id and current action for last object" do
      #    segment = ActionController::Routing::DynamicSegment.new(:id)
      #    assert_equal({:action => 'update', :id => @leo.id.to_s}, @collection.path_for_model(segment))
      #  end
      #
      #  should "return show action and object id for not last object" do
      #    segment = ActionController::Routing::DynamicSegment.new(:movie_id)
      #    assert_equal({:action => 'show', :movie_id => @titanic.id.to_s}, @collection.path_for_model(segment))
      #  end
      #end

      #context "path_for_controller" do
      #  should "return index action and controller name" do
      #    segment = ActionController::Routing::StaticSegment.new("movies")
      #    assert_equal({:action => 'index', :controller => 'movies'}, @collection.path_for_controller(segment))
      #  end
      #
      #  should "return new action and controller name for new action segment" do
      #    segment = ActionController::Routing::StaticSegment.new("new")
      #    assert_equal({:action => 'new', :controller => 'actors'}, @collection.path_for_controller(segment))
      #  end
      #end

      context "repaired_model_path" do
        should "return repaired path if model is connected with controller" do
          path = {:action => "show", :controller => "movies", :movie_id => 3}
          assert_equal({:action => "show", :controller => "movies", :id => 3}, @collection.repaired_model_path(path))
        end

        should "return same path if model is not connected with controller" do
          path = {:action => "show", :controller => "actors", :movie_id => 3}
          assert_equal(path, @collection.repaired_model_path(path))
        end
      end

      context "make_pathes" do
        should "return patches array for objects" do
          assert_equal([
          {:action => 'index', :controller => 'countries'},
          {:action => 'show', :controller => 'countries', :id => @usa.id.to_s},
          {:action => 'index', :controller => 'movies', :country_id => @usa.id.to_s},
          {:action => 'show', :controller => 'movies', :country_id => @usa.id.to_s, :id => @titanic.id.to_s},
          {:action => 'index', :controller => 'actors', :country_id => @usa.id.to_s, :movie_id => @titanic.id.to_s},
          {:action => 'update', :controller => 'actors', :country_id => @usa.id.to_s, :movie_id => @titanic.id.to_s, :id => @leo.id.to_s}
          ], @collection.make_pathes)
        end

        should "return patches array for objects for new action" do
          #Collection.any_instance.stubs(:request_path => "/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :request_method => :get)
          collection = Collection.new(stub_request("/countries/#{@usa.id}/movies/#{@titanic.id}/actors/new", :get))
          assert_equal([
          {:action => 'index', :controller => 'countries'},
          {:action => 'show', :controller => 'countries', :id => @usa.id.to_s},
          {:action => 'index', :controller => 'movies', :country_id => @usa.id.to_s},
          {:action => 'show', :controller => 'movies', :country_id => @usa.id.to_s, :id => @titanic.id.to_s},
          {:action => 'index', :controller => 'actors', :country_id => @usa.id.to_s, :movie_id => @titanic.id.to_s},
          {:action => 'new', :controller => 'actors', :country_id => @usa.id.to_s, :movie_id => @titanic.id.to_s}
          ], collection.make_pathes)
        end
      end

      context "make_breadcrumbs" do
        setup do
          @results = @collection.make_breadcrumbs({:prefix => :every})
        end

        should "return array of breadcrumbs objects" do
          assert_equal(@collection.objects.size + 1, @results.size)
          @results.uniq == [EasyCrumbs::Breadcrumb]
        end

        should "last breadcrumb have name with action prefix" do
          assert_equal("Update Leonardo Di Caprio", @results.last.name)
        end
      end

      context "render" do
        setup do
          @results = [  "<a href=\"/\">Home</a>",
                      "<a href=\"/countries\">Countries list</a>",
                      "<a href=\"/countries/#{@usa.id}\">United States of America</a>",
                      "<a href=\"/countries/#{@usa.id}/movies\">Movies</a>",
                      "<a href=\"/countries/#{@usa.id}/movies/#{@titanic.id}\">Movie</a>",
                      "<a href=\"/countries/#{@usa.id}/movies/#{@titanic.id}/actors\">Actors</a>",
                      "<a href=\"/countries/#{@usa.id}/movies/#{@titanic.id}/actors/#{@leo.id}\">Leonardo Di Caprio</a>"]
        end

        context "separator" do
          should "render all breadcrumbs with links and standard separator" do
            assert_equal(@results.join(" > "), @collection.render)
          end

          should "render custom separator" do
            assert_equal(@results.join(" | "), @collection.render(:separator => " | "))
          end
        end

        context "last item not link" do
          should "last item not be link when last_link option is false" do
            @results = @results[0..-2] << "Leonardo Di Caprio"
            assert_equal(@results.join(" > "), @collection.render(:last_link => false))
          end
        end
      end

    end
  end
end

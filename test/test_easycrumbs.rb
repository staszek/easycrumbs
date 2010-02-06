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
          should "return breadcrumb column by default" do
            assert_equal("United States of America", Breadcrumb.new(@usa).name)
          end
          
          should "return name column if someone set it" do
            assert_equal(@titanic.name, Breadcrumb.new(@titanic, :name_column => "name").name)
          end
          
          should "return specyfic name using breadcrumb method" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo).name)
          end
          
          should "raise exception if can not find name" do
            assert_raise(NoName) {  Breadcrumb.new(@leo, :name_column => "wrong_column")}
          end
          
          should "return name with prefix if action is passed by parameter and it is one of defaults(new or edit)" do
            assert_equal("Edit Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "edit").name)
          end
          
          context "with prefix option" do
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
          end
        end
      end
    end
  
    context "Collection" do
    end
  
    context "View Helpers" do
    end
  end
end

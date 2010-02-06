require 'helper'

class TestEasycrumbs < Test::Unit::TestCase
  context "EasyCrumbs tests" do
    setup do
      @usa = Country.create(:name => "USA")
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
  
    context "Collection" do
    end
  
    context "View Helpers" do
    end
  end
end

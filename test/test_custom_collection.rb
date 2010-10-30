require 'helper'

class CustomCollection < EasyCrumbs::Collection
  def initialize(request, options = {})
    object = options[:object]
    collection = []
    path = {:action => 'show', :controller => 'countries'}

    while(!object.nil?)
      collection << Breadcrumb.new(object, options.merge(:path => path.merge(:id => object.id)))
      object = object.parent
    end
    @breadcrumbs = collection.reverse
  end
end

class TestCustomCollection < Test::Unit::TestCase
  context "Custom collection tests" do
    setup do
      @usa = Country.create(:breadcrumb => "USA")
      @usa_son = Country.create(:breadcrumb => "USA son")
      @usa_grandson = Country.create(:breadcrumb => "USA grandson")

      @usa_grandson.stubs(:parent => @usa_son, :id => 3)
      @usa_son.stubs(:parent => @usa, :id => 2)
      @usa.stubs(:parent => nil, :id => 1)
    end

    context "Collection of breadcrumbs" do
      should "reurned names be proper" do
        result = ['USA', "USA son", "USA grandson"]
        assert_equal(result, CustomCollection.new('request object', {:object => @usa_grandson}).breadcrumbs.map(&:name))
      end

      should "reurned paths be proper" do
        result = ['/countries/1', "/countries/2", "/countries/3"]
        assert_equal(result, CustomCollection.new('request object', {:object => @usa_grandson}).breadcrumbs.map(&:path))
      end
    end
  end
end
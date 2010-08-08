require 'rubygems'
require 'test/unit'
require 'shoulda'
require "mocha"
require 'active_record'
require "action_view"
require "action_controller"
require "routes"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'easycrumbs'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :countries do |t|
    t.string :name
    t.string :breadcrumb
  end

  create_table :movies do |t|
    t.string :name
    t.integer :country_id
  end

  create_table :actors do |t|
    t.string :first_name
    t.string :last_name
    t.integer :movie_id
  end
end


# =========== Rails Classes and Objects ===========

include EasyCrumbs

class Country < ActiveRecord::Base
  has_many :movies
end

class Movie < ActiveRecord::Base
  has_many :actors
  belongs_to :country
end

class Actor < ActiveRecord::Base
  belongs_to :movie

  def breadcrumb
    "#{first_name} #{last_name}"
  end
end

class ApplicationController < ActionController::Base
end

class CountriesController < ApplicationController
  def breadcrumb
    "Countries list"
  end
end

class MoviesController < ApplicationController
end

class ActorsController < ApplicationController
end

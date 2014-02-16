require File.expand_path('../schema', __FILE__)

class Employee < ::ActiveRecord::Base
  validates_exclusion_of :name, in: ['Invalid']
end

require 'stubs/data_model'
require 'stubs/spreadsheet'

class Employee < DataModel
  attr_accessor :name, :birth_date, :department, :department_id

  def validate
    @errors << 'Invalid name' if name == 'Invalid'
  end
end

class EmployeeImporter < ActiveImporter::Base
  imports Employee

  column 'Name', :name
  column 'Birth Date', :birth_date
  column 'Manager'
  column '  Department ', :department_id do |value|
    find_department(value)
  end

  def find_department(name)
    name.length # Quick dummy way to get an integer out of a string
  end

  ActiveImporter::Base::EVENTS.each do |event_name|
    define_method(event_name) {}
    on(event_name) { send event_name }
  end
end

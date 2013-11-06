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
  column '  Department ', :department_id do |value|
    value.length # Quick dummy way to get an integer out of a string
  end
end

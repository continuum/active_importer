class EmployeeBaseImporter < ActiveImporter::Base
  on(:import_finished) { base_import_finished }

  skip_rows_if do
    row['Name'] == 'BaseSkip'
  end

  private

  def base_import_finished
  end
end

class EmployeeImporter < EmployeeBaseImporter
  imports Employee

  column 'Name', :name
  column 'Birth Date', :birth_date
  column 'Manager'
  column 'Unused', :unused_field, optional: true
  column 'Extra', optional: true
  column '  Department ', :department_id do |value|
    find_department(value)
  end

  on :row_processing do
    abort!('Row cannot be processed') if row['Name'] == 'Abort'
  end

  skip_rows_if do
    row['Name'] == 'Skip'
  end

  def find_department(name)
    name.length # Quick dummy way to get an integer out of a string
  end

  ActiveImporter::Base::EVENTS.each do |event_name|
    define_method(event_name) {}
    on(event_name) { send event_name }
  end
end

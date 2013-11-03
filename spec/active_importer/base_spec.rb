require 'spec_helper'
require 'stubs/employee'

describe ActiveImporter::Base do
  let(:spreadsheet_data) do
    [
      ['Name', 'Birth Date', 'Department'],
      ['John Doe', '2013-10-25', 'IT'],
      ['Jane Doe', '2013-10-26', 'Sales'],
    ]
  end

  it 'imports all data from the spreadsheet into the model' do
    expect(Roo::Spreadsheet).to receive(:new).and_return { Spreadsheet.new(spreadsheet_data) }
    expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
  end
end

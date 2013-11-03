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

  context 'when there are rows with errors' do
    let(:spreadsheet_data) do
      [
        ['Name', 'Birth Date', 'Department'],
        ['John Doe', '2013-10-25', 'IT'],
        ['Invalid', '2013-10-24', 'Management'],
        ['Invalid', '2013-10-24', 'Accounting'],
        ['Jane Doe', '2013-10-26', 'Sales'],
      ]
    end

    before do
      expect(Roo::Spreadsheet).to receive(:new).and_return { Spreadsheet.new(spreadsheet_data) }
    end

    it 'does not import those rows' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end

    it 'notifies about each error' do
      importer = EmployeeImporter.new('/dummy/file')
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:row_error).twice
      EmployeeImporter.import('/dummy/file')
    end
  end
end

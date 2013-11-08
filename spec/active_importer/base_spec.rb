require 'spec_helper'
require 'stubs/employee'

describe ActiveImporter::Base do
  let(:spreadsheet_data) do
    [
      [' Name ', 'Birth Date', 'Department', 'Manager'],
      ['John Doe', '2013-10-25', 'IT'],
      ['Jane Doe', '2013-10-26', 'Sales'],
    ]
  end

  let(:importer) { EmployeeImporter.new('/dummy/file') }

  before do
    expect(Roo::Spreadsheet).to receive(:open).and_return { Spreadsheet.new(spreadsheet_data) }
  end

  it 'imports all data from the spreadsheet into the model' do
    expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
  end

  it 'notifies when each row has been imported successfully' do
    expect(EmployeeImporter).to receive(:new).once.and_return(importer)
    expect(importer).not_to receive(:row_error)
    expect(importer).to receive(:row_success).twice
    EmployeeImporter.import('/dummy/file')
  end

  it 'notifies when the import process starts and finishes' do
    expect(EmployeeImporter).to receive(:new).once.and_return(importer)
    expect(importer).to receive(:import_started).once
    expect(importer).to receive(:import_finished).once
    EmployeeImporter.import('/dummy/file')
  end

  context 'when there are rows with errors' do
    let(:spreadsheet_data) do
      [
        ['Name', 'Birth Date', 'Department', 'Manager'],
        ['John Doe', '2013-10-25', 'IT'],
        ['Invalid', '2013-10-24', 'Management'],
        ['Invalid', '2013-10-24', 'Accounting'],
        ['Jane Doe', '2013-10-26', 'Sales'],
      ]
    end

    it 'does not import those rows' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end

    it 'notifies about each error' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:row_error).twice
      expect(importer).to receive(:row_success).twice
      EmployeeImporter.import('/dummy/file')
    end

    it 'keeps track of each error' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect { EmployeeImporter.import('/dummy/file') }.to change(importer.row_errors, :count).by(2)
    end

    it 'still notifies all rows as processed' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:row_processed).exactly(4).times
      EmployeeImporter.import('/dummy/file')
    end
  end

  context 'when the import fails' do
    let(:spreadsheet_data) do
      [
        ['Name', 'Birth Date', 'Manager'],
        ['John Doe', '2013-10-25'],
        ['Jane Doe', '2013-10-26'],
      ]
    end

    it 'notifies the failure' do
      expect_any_instance_of(EmployeeImporter).to receive(:import_failed)
      EmployeeImporter.import('/dummy/file')
    end
  end

  context 'when header row is not the first one' do
    let(:spreadsheet_data) do
      [
        [],
        ['List of employees', '', 'Company Name'],
        ['Ordered by', 'Birth Date'],
        ['Name', 'Department', 'Birth Date', 'Manager'],
        ['John Doe', 'IT', '2013-10-25'],
        ['Jane Doe', 'Sales', '2013-10-26'],
      ]
    end

    it 'smartly skips any rows before the header' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end
  end

  describe '.fetch_model' do
    let(:model) { Employee.new }

    it 'controls what model instance is loaded for each given row' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:fetch_model).twice.and_return(model)
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(1)
    end
  end

  describe '.hook' do
    it 'allows the importer to modify the model for each row' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:hook).twice
      EmployeeImporter.import('/dummy/file')
    end
  end
end

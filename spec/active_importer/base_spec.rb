require 'spec_helper'

describe ActiveImporter::Base do
  let(:spreadsheet_data) do
    [
      [' Name ', 'Birth Date', 'Department', 'Manager'],
      ['John Doe', '2013-10-25', 'IT'],
      ['Jane Doe', '2013-10-26', 'Sales'],
    ]
  end

  let(:spreadsheet_data_with_errors) do
    [
      ['List of employees'],
      ['Name', 'Birth Date', 'Department', 'Manager'],
      ['John Doe', '2013-10-25', 'IT'],
      ['Invalid', '2013-10-24', 'Management'],
      ['Invalid', '2013-10-24', 'Accounting'],
      ['Jane Doe', '2013-10-26', 'Sales'],
    ]
  end

  let(:importer) { EmployeeImporter.new('/dummy/file') }

  before do
    allow(Roo::Spreadsheet).to receive(:open).at_least(:once).and_return Spreadsheet.new(spreadsheet_data)
    EmployeeImporter.instance_variable_set(:@fetch_model_block, nil)
    EmployeeImporter.instance_variable_set(:@sheet_index, nil)
    EmployeeImporter.transactional(false)
  end

  describe '.column' do
    it 'does not allow a column with block and no attribute' do
      expect { EmployeeImporter.column('Dummy') {} }.to raise_error
    end
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
    expect(importer).to receive(:base_import_finished).once
    EmployeeImporter.import('/dummy/file')
  end

  it 'can receive custom parameters via the `params` option' do
    importer = EmployeeImporter.new('/dummy/file', params: 'anything')
    expect(importer.params).to eql('anything')
  end

  context do
    let(:spreadsheet_data) do
      [
        [' Name ', 'Birth Date', 'Department', 'Unused', 'Manager'],
        ['Mary', '2013-10-25', 'IT', 'hello'],
        ['John', '2013-10-26', 'Sales', 'world'],
      ]
    end

    it 'processes optional columns when present' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect {
        EmployeeImporter.import('/dummy/file')
      }.to change(Employee.where.not(unused_field: nil), :count).by(2)
    end
  end

  context do
    let(:spreadsheet_data) { spreadsheet_data_with_errors }

    before do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      EmployeeImporter.import('/dummy/file')
    end

    describe '.row_processed_count' do
      it 'reports the number of rows processed' do
        expect(importer.row_processed_count).to eq(4)
      end
    end

    describe '.row_success_count' do
      it 'reports the number of rows imported successfully' do
        expect(importer.row_success_count).to eq(2)
      end
    end

    describe '.row_error_count' do
      it 'reports the number of rows with errors' do
        expect(importer.row_error_count).to eq(2)
      end
    end
  end

  context 'when there are rows with errors' do
    let(:spreadsheet_data) { spreadsheet_data_with_errors }

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
      expect {
        EmployeeImporter.import('/dummy/file')
      }.to raise_error
    end
  end

  context 'when header row is not the first one' do
    let(:spreadsheet_data) do
      [
        [],
        ['List of employees', '', nil, 'Company Name'],
        ['Ordered by', 'Birth Date'],
        ['Name', 'Department', 'Birth Date', 'Manager'],
        ['John Doe', 'IT', '2013-10-25'],
        ['Jane Doe', 'Sales', '2013-10-26'],
      ]
    end

    it 'smartly skips any rows before the header' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end

    it 'reports the number of processed rows correctly' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      EmployeeImporter.import('/dummy/file')
      expect(importer.row_processed_count).to eq(2)
    end
  end

  context 'when header row is indented' do
    let(:spreadsheet_data) do
      [
        ['', 'Name'    , 'Department', 'Birth Date', 'Manager'],
        ['', 'John Doe', 'IT'        , '2013-10-25'           ],
      ]
    end

    it 'ignores empty columns' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      EmployeeImporter.import('/dummy/file')
      expect(importer.row['']).to eq(nil)
    end
  end

  describe '.fetch_model' do
    it 'controls what model instance is loaded for each given row' do
      model = Employee.new
      EmployeeImporter.fetch_model { model }
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(1)
    end
  end

  describe 'row_processing event' do
    it 'allows the importer to modify the model for each row' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:row_processing).twice
      EmployeeImporter.import('/dummy/file')
    end
  end

  context 'when spreadsheet has multiple sheets' do
    let(:spreadsheet_data) do
      {
        "Employees" => [
          [' Name ', 'Birth Date', 'Department', 'Manager'],
          ['John Doe', '2013-10-25', 'IT'],
          ['Jane Doe', '2013-10-26', 'Sales'],
        ],
        "Outstanding employees" => [
          [' Name ', 'Birth Date', 'Department', 'Manager'],
          ['Jane Doe', '2013-10-26', 'Sales'],
        ],
      }
    end

    it 'uses the first sheet by default' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end

    it 'uses another sheet if instructed to do so' do
      EmployeeImporter.sheet 1
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
      EmployeeImporter.sheet "Outstanding employees"
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(1)
    end

    it 'fails if the specified sheet cannot be found' do
      expect_any_instance_of(EmployeeImporter).to receive(:import_failed)
      EmployeeImporter.sheet 5
      expect {
        EmployeeImporter.import('/dummy/file')
      }.to raise_error
    end
  end

  describe '#abort!' do
    let(:spreadsheet_data) do
      [
        [' Name ', 'Birth Date', 'Department', 'Manager'],
        ['John Doe', '2013-10-25', 'IT'],
        ['Abort', '2013-10-25', 'IT'],
        ['Jane Doe', '2013-10-26', 'Sales'],
      ]
    end

    it 'causes the import process to abort without processing any more rows' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(1)
    end

    it 'does not report an error for the row where the abortion occured' do
      expect(importer).not_to receive(:row_error)
      EmployeeImporter.import('/dummy/file')
    end
  end

  describe '.skip_rows_if' do
    let(:spreadsheet_data) do
      [
        [' Name ', 'Birth Date', 'Department', 'Manager'],
        ['Skip', '2013-10-25', 'IT'],
        ['John Doe', '2013-10-25', 'IT'],
        ['BaseSkip', '2013-10-25', 'IT'],
        ['Jane Doe', '2013-10-26', 'Sales'],
      ]
    end

    it 'allows the user to define conditions under which rows should be skipped' do
      expect { EmployeeImporter.import('/dummy/file') }.to change(Employee, :count).by(2)
    end

    it 'invokes event :row_skipped for each skipped row' do
      expect(EmployeeImporter).to receive(:new).once.and_return(importer)
      expect(importer).to receive(:row_skipped).twice
      EmployeeImporter.import('/dummy/file')
    end
  end

  describe '#initialize' do
    context "when invoked with option 'transactional: true'" do
      it 'declares the instance to be transactional even when the importer class is not' do
        EmployeeImporter.transactional(false)
        importer = EmployeeImporter.new('/dummy/file', transactional: true)
        expect(importer).to be_transactional
      end
    end

    context "when invoked with option 'transactional: false'" do
      it 'does not override the class-wide setting' do
        EmployeeImporter.transactional(true)
        expect_any_instance_of(EmployeeImporter).to receive(:import_failed)
        expect {
          EmployeeImporter.new('/dummy/file', transactional: false)
        }.to raise_error
      end
    end
  end

  describe '.transactional' do
    let(:spreadsheet_data) { spreadsheet_data_with_errors }

    before(:each) do
      allow(EmployeeImporter).to receive(:new).once.and_return(importer)
    end

    context 'when called with true as an argument' do
      before(:each) { EmployeeImporter.transactional(true) }

      it 'declares all importers of its kind to be transactional' do
        expect(EmployeeImporter).to be_transactional
        importer = EmployeeImporter.new('/dummy/file')
        expect(importer).to be_transactional
      end

      it 'runs the import process within a transaction' do
        expect {
          EmployeeImporter.import('/dummy/file') rescue nil
        }.not_to change(Employee, :count)
      end

      it 'exposes the exception that aborted the transaction' do
        expect {
          EmployeeImporter.import('/dummy/file')
        }.to raise_error
      end

      it 'still invokes the :row_error event' do
        expect(importer).to receive(:row_error)
        EmployeeImporter.import('/dummy/file') rescue nil
      end

      it 'still invokes the :import_finished event' do
        expect(importer).to receive(:import_finished)
        EmployeeImporter.import('/dummy/file') rescue nil
      end

      it 'invokes the :import_aborted event' do
        expect(importer).to receive(:import_aborted)
        EmployeeImporter.import('/dummy/file') rescue nil
      end
    end

    context 'when called with false as an argument' do
      it 'does not run the import process within a transactio' do
        EmployeeImporter.transactional(false)
        expect {
          EmployeeImporter.import('/dummy/file')
        }.to change(Employee, :count).by(2)
      end

      it 'declares all importers of its kind not to be transactional' do
        expect(EmployeeImporter).not_to be_transactional
        importer = EmployeeImporter.new('/dummy/file')
        expect(importer).not_to be_transactional
      end
    end
  end
end

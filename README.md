# ActiveImporter

Define importers that load tabular data from spreadsheets or CSV files into any ActiveRecord-like ORM.

## Installation

Add this line to your application's Gemfile:

    gem 'active_importer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_importer

## Usage

Define classes that you instruct on how to import data into data models.

```ruby
class EmployeeImporter < ActiveImporter::Base
  imports Employee

  column 'First name', :first_name
  column 'Last name', :last_name
  column 'Department', :department do |department_name|
    Department.find_by(name: department_name)
  end
end
```

The importer defines what data model it imports data into, and how columns in
the data source map to fields in the model.  Also, by providing a block, the
source value can be processed before being stored, as shown with the
'Department' column in the example above.

Once defined, importers can be invoked to import a given data file.

```ruby
EmployeeImporter.import('/path/to/file.xls')
```

The data file is expected to contain columns with titles corresponding to the
columns declared.  Any extra columns are ignored.  Any errors while processing
the data file does not interrupt the whole process.  Instead, errors are
notified via some callbacks defined in the importer (see below).

### Supported formats

This library currently supports reading from most spreadsheet formats, thanks
to the wonderfull [roo](https://github.com/Empact/roo) gem.  Specifically, the
following formats are supported:

* OpenOffice
* Excel
* Google spreadsheets
* Excelx
* LibreOffice
* CSV

The spreadsheet contents are scanned, row by row, until a row is found that
matches the expect header column, which should contain header cells for all the
columns declared in the importer.  If no such row is found, the spreadsheet
processing fails without importing any data.

If the header row is found, data is scanned from the next row on, until the end
of the spreadsheet.

### Callbacks

TODO: Document callbacks

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

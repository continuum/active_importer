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

An importer class can define blocks of code acting as callbacks, to be notified
of certain events that occur while importing the data.

```ruby
class EmployeeImporter < ActiveImporter::Base
  imports Employee

  attr_reader :row_count

  column 'First name', :first_name
  column 'Last name', :last_name
  column 'Department', :department do |department_name|
    Department.find_by(name: department_name)
  end

  on :import_started do
    @row_count = 0
  end

  on :row_processed do
    @row_count += 1
  end

  on :import_finished do
    send_notification("Data imported successfully!")
  end

  on :import_failed do |exception|
    send_notification("Fatal error while importing data: #{exception.message}")
  end

  private

  def send_notification(message)
    # ...
  end
end
```

The supported events are:

- **import_failed:** Fired once **before** the beginning of the data
  processing, if the input data cannot be processed for some reason.  If this
  event is fired by an importer, none of its other events are ever fired.
- **import_started:** Fired once at the beginning of the data processing,
  before the first row is processed.
- **row_processed:** Fired once for each row that has been processed,
  regardless of whether it resulted in success or error.
- **row_success:** Fired once for each row that was imported successfully into
  the data model.
- **row_error:** Fired once for each row that was **not** imported successfully
  into the data model.
- **import_finished:** Fired once **after** all rows have been processed.

More than one block of code can be provided for each of these events, and they
will all be invoked in the same order in which they were declared.  All blocks
are executed in the context of the importer instance, so they have access to
all the importer attributes and instance variables.  Error-related events
(`:import_failed` and `:row_error`) pass to the blocks the instance of the
exception that provoked the error condition.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

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

### File extension and supported formats

This library currently supports reading from most spreadsheet formats, thanks
to the wonderfull [roo](https://github.com/Empact/roo) gem.  Specifically, the
following formats are supported:

* OpenOffice
* Excel
* Google spreadsheets
* Excelx
* LibreOffice
* CSV

The filename should contain the extension so the library knows which format to
expect.  If the filename does not include the extension, or if for some reason
you need to force the extension to something else, you can pass it as an option
to the `import` method, like shown below:

```ruby
EmployeeImporter.import('/path/to/file_without_extension', :extension => :xlsx)
```

This is useful in cases where you are using an uploaded file, which are usually
stored in temporary files with random names and no extension.

### Header rows

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

  column 'First name'
  column 'Last name'
  column 'Department', :department do |department_name|
    Department.find_by(name: department_name)
  end

  on :row_processing do
    model.full_name = [row['First name'], row['Last name']].join(' ')
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
- **row_processing:** Fired while the row is being processed to be imported
  into a model instance.
- **row_skipped:** Fired once for each row that matches the `skip_rows_if`
  condition, if any.
- **row_processed:** Fired once for each row that has been processed,
  regardless of whether it resulted in success or error.
- **row_success:** Fired once for each row that was imported successfully into
  the data model.
- **row_error:** Fired once for each row that was **not** imported successfully
  into the data model.
- **import_finished:** Fired once **after** all rows have been processed.
- **import_aborted:** Fired once if the import process is aborted by invoking
  `abort!`.

More than one block of code can be provided for each of these events, and they
will all be invoked in the same order in which they were declared.  All blocks
are executed in the context of the importer instance, so they have access to
all the importer attributes and instance variables.  Error-related events
(`:import_failed` and `:row_error`) pass to the blocks the instance of the
exception that provoked the error condition.

Additionally, all the `row_*` events have access to the `row` and `model`
variables, which reference the spreadsheet row being processed, and the model
object where the row data is being stored, respectively.  This feature is
specifically useful for the `:row_processing` event handler, which is triggered
while a row is being processed, and before the corresponding data model is
saved.  This allows to define any complex data-import logic that cannot be
expressed in terms of mapping a column to a data field.

### Selecting the model instance to import into

By default, the importer will attempt to generate a new model instance per row
processed.  The importer can be instructed to update records instead, if they
already exist, instead of always attempting to generate a new one.

```ruby
class EmployeeImporter
  imports Employee

  fetch_model do
    Employee.where(first_name: row['First name'], last_name: row['Last name']).first_or_initialize
  end

  # ...
end
```

The code above specifies that, for each row, the importer should attempt to
find an existing model for the employee with the first and last name in the row
being processed.  If this record exist, the row data will be used to update the
given model instance.  Otherwise, a new employee record will be created.

### Selecting the sheet to get data from

Spreadsheet files often have more than one sheet of data, so it is desirable to
select which sheet to use when importing.

```ruby
class EmployeeImporter
  imports Employee

  sheet "Employees"

  # ...
end
```

The importer defined above specifies that data should be read from a sheet
named "Employees".  By default an importer will read from the first sheet in
the spreadsheet.

Also, sheets can be specified by name or by index, starting by 1, which is the
first sheet.  For instance, the following importer will read data from the
third sheet, no matter what's its name.

```ruby
class EmployeeImporter
  imports Employee

  sheet 3

  # ...
end
```

### Transactions

Importers can be instructed to work within a database transaction.

```ruby
class EmployeeImporter
  imports Employee
  transactional

  # ...
end
```

This transaction mode works transparently when using ActiveRecord and
[DataMapper](http://datamapper.org), two of the most popular Ruby ORM's.  Any
other library can be easily adapted to use the same approach.

It's important to note that when this mode is activated, the importer will
implicitly abort when a row error occurs, and the exception that caused the
error will be exposed to the caller of `EmployeeImporter.import(filename)`.
And of course, any changes performed to the database during the import process
prior to the error will be rolled back.

Callbacks are still invoked as usual.  When a row error occurs, the
`:row_error` event is still invoked, as well as the `:import_aborted` and
`:import_finished` events, in that order.

Transactional mode is in an alpha stage of testing, so it is still not included
in the released gem.  If you wanna give it a try, put the following in your
`Gemfile`:

    gem 'active_importer', github: 'continuum/active_importer', branch: 'feature/transactions'

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

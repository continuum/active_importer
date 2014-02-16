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

## Documentation

For mote detailed information about the different aspects of importing data
with `active_importer`, refer to the following sections in the [wiki]():

[wiki]: https://github.com/continuum/active_importer/wiki

* [Understanding how spreadsheets are parsed](https://github.com/continuum/active_importer/wiki/Understanding-how-spreadsheets-are-parsed)
* [Mapping columns to attributes](https://github.com/continuum/active_importer/wiki/Mapping-columns-to-attributes)
* [Custom data processing](https://github.com/continuum/active_importer/wiki/Custom-data-processing)
* [Helper methods](https://github.com/continuum/active_importer/wiki/Helper-methods)
* [File extension and supported formats](https://github.com/continuum/active_importer/wiki/File-extension-and-supported-formats)
* [Passing custom parameters](https://github.com/continuum/active_importer/wiki/Custom-parameters)
* [Events and callbacks](https://github.com/continuum/active_importer/wiki/Callbacks)
* [Selecting the model instance to import into (Update instead of create)](https://github.com/continuum/active_importer/wiki/Update-instead-of-create)
* [Error handling](https://github.com/continuum/active_importer/wiki/Error-handling)
* [Selecting the sheet to get data from](https://github.com/continuum/active_importer/wiki/Selecting-the-sheet-to-work-with)
* [Advanced features](https://github.com/continuum/active_importer/wiki/Advanced-and-experimental-features)

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

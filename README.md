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
with `active_importer`, refer to the following sections in the [wiki](https://github.com/continuum/active_importer/wiki).

### Getting started

* [Understanding how spreadsheets are parsed](https://github.com/continuum/active_importer/wiki/Understanding-how-spreadsheets-are-parsed)
* [Mapping columns to attributes](https://github.com/continuum/active_importer/wiki/Mapping-columns-to-attributes)

### Diving in

* [Custom data processing](https://github.com/continuum/active_importer/wiki/Custom-data-processing)
* [Helper methods](https://github.com/continuum/active_importer/wiki/Helper-methods)
* [File extension and supported formats](https://github.com/continuum/active_importer/wiki/File-extension-and-supported-formats)
* [Passing custom parameters](https://github.com/continuum/active_importer/wiki/Custom-parameters)
* [Events and callbacks](https://github.com/continuum/active_importer/wiki/Callbacks)
* [Selecting the model instance to import into (Update instead of create)](https://github.com/continuum/active_importer/wiki/Update-instead-of-create)
* [Error handling](https://github.com/continuum/active_importer/wiki/Error-handling)
* [Selecting the sheet to get data from](https://github.com/continuum/active_importer/wiki/Selecting-the-sheet-to-work-with)
* [Skipping rows](https://github.com/continuum/active_importer/wiki/Skipping-rows)

### Advanced features

* [Aborting the import process](https://github.com/continuum/active_importer/wiki/Aborting-the-import-process)
* [Transactional importers](https://github.com/continuum/active_importer/wiki/Transactional-importers)

## Contributing

Contributions are welcome! Take a look at our [contributions guide][] for
details.

[contributions guide]: https://github.com/continuum/active_importer/wiki/Contributing

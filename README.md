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

### Callbacks

TODO: Document callbacks

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

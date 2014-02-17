require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.logger = Logger.new('/dev/null')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :employees, :force => true do |t|
    t.column :name, :string
    t.column :birth_date, :string
    t.column :department_id, :integer
    t.column :unused_field, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
end

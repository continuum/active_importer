require 'roo'

module ActiveImporter
  class Base

    #
    # DSL and class variables
    #

    @@model_class = nil
    @@columns = {}

    def self.imports(model_class)
      @@model_class = model_class
    end

    def self.columns
      @@columns
    end

    def self.column(title, field, &block)
      if columns[title]
        raise "Duplicate importer column '#{title}'"
      end
      columns[title] = { field_name: field, transform: block }
    end

    def self.import(file, options = {})
      new(file, options).import
    end

    #
    # Implementation
    #

    attr_reader :header, :row, :model
    attr_reader :row_count

    def initialize(file, options = {})
      @book = Roo::Spreadsheet.new(file, options)
      @header = @book.row(1)
      @data_row_indices = (2..@book.count)
      @row_count = @data_row_indices.count
    end

    def fetch_model
      @model = @@model_class.new
    end

    def import
      @data_row_indices.each do |index|
        @row = row_to_hash @book.row(index)
        import_row
      end
    end

    def hook
    end

    def row_success
    end

    def row_error(error_message)
    end

    private

    def import_row
      fetch_model
      build_model
      model.save!
      row_success
    rescue => e
      row_error(e.message)
    end

    def build_model
      row.each_pair do |key, value|
        column_def = @@columns[key]
        next if column_def.nil?
        field_name = column_def[:field_name]
        transform = column_def[:transform]
        value = transform.call(value) if transform
        model[field_name] = value
      end
      hook
    end

    def row_to_hash(row)
      hash = {}
      row.each_with_index do |value, index|
        hash[@header[index]] = value
      end
      hash
    end
  end
end

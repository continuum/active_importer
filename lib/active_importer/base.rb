require 'roo'

module ActiveImporter
  class Base

    #
    # DSL and class variables
    #

    @model_class = nil
    @columns = {}

    def self.imports(klass)
      @model_class = klass
    end

    def self.columns
      @columns ||= {}
    end

    def self.model_class
      @model_class
    end

    def model_class
      self.class.model_class
    end

    def self.column(title, field = nil, &block)
      title = title.strip
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
    attr_reader :row_count, :row_index
    attr_reader :row_errors
    attr_reader :context

    def initialize(file, options = {})
      @row_errors = []
      @context = options.delete(:context)

      @book = Roo::Spreadsheet.open(file, options)
      load_header

      @data_row_indices = ((@header_index+1)..@book.last_row)
      @row_count = @data_row_indices.count
    rescue => e
      @book = @header = nil
      @row_count = 0
      @row_index = 1
      import_failed(e.message)
    end

    def fetch_model
      model_class.new
    end

    def import
      return if @book.nil?
      @data_row_indices.each do |index|
        @row_index = index
        @row = row_to_hash @book.row(index)
        import_row
      end
      import_finished
    end

    def row_processed_count
      row_index - 1
    end

    def row_success_count
      row_processed_count - row_errors.count
    end

    def row_error_count
      row_errors.count
    end

    def hook
    end

    def row_success
    end

    def row_error(error_message)
    end

    def import_failed(error_message)
    end

    def import_finished
    end

    private

    def columns
      self.class.columns
    end

    def find_header_index
      (1..@book.last_row).each do |index|
        row = @book.row(index).map(&:strip)
        return index if columns.keys.all? { |item| row.include?(item) }
      end
      return nil
    end

    def load_header
      @header_index = find_header_index
      if @header_index
        @header = @book.row(@header_index).map(&:strip)
      else
        raise 'Spreadsheet does not contain all the expected columns'
      end
    end

    def import_row
      begin
        @model = fetch_model
        build_model
        model.save!
      rescue => e
        @row_errors << { row_index: row_index, error_message: e.message }
        row_error(e.message)
        return false
      end
      row_success
      true
    end

    def build_model
      row.each_pair do |key, value|
        column_def = columns[key]
        next if column_def.nil? || column_def[:field_name].nil?
        field_name = column_def[:field_name]
        transform = column_def[:transform]
        value = self.instance_exec(value, &transform) if transform
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

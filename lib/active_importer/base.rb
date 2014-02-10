require 'roo'

module ActiveImporter
  class Base

    #
    # DSL and class variables
    #

    @abort_message = nil

    def abort!(message)
      @abort_message = message
    end

    def aborted?
      !!@abort_message
    end

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

    def self.sheet(index)
      @sheet_index = index
    end

    def self.fetch_model(&block)
      @fetch_model_block = block
    end

    def self.fetch_model_block
      @fetch_model_block
    end

    def self.skip_rows_if(&block)
      @skip_rows_block = block
    end

    def self.skip_rows_block
      @skip_rows_block
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
    # Callbacks
    #

    EVENTS = [
      :row_success,
      :row_error,
      :row_processing,
      :row_skipped,
      :row_processed,
      :import_started,
      :import_finished,
      :import_failed,
      :import_aborted,
    ]

    def self.event_handlers
      @event_handlers ||= EVENTS.inject({}) { |hash, event| hash.merge({event => []}) }
    end

    def self.on(event, &block)
      raise "Unknown ActiveImporter event '#{event}'" unless EVENTS.include?(event)
      event_handlers[event] << block
    end

    def fire_event(event, param = nil)
      self.class.send(:fire_event, self, event, param)
      unless self.class == ActiveImporter::Base
        self.class.superclass.send(:fire_event, self, event, param)
      end
    end

    def self.fire_event(instance, event, param = nil)
      event_handlers[event].each do |block|
        instance.instance_exec(param, &block)
      end
    end

    private :fire_event

    class << self
      private :fire_event
      private :fetch_model_block
    end

    #
    # Implementation
    #

    attr_reader :header, :row, :model
    attr_reader :row_count, :row_index
    attr_reader :row_errors
    attr_reader :params

    def initialize(file, options = {})
      @row_errors = []
      @params = options.delete(:params)

      @book = Roo::Spreadsheet.open(file, options)
      load_sheet
      load_header

      @data_row_indices = ((@header_index+1)..@book.last_row)
      @row_count = @data_row_indices.count
    rescue => e
      @book = @header = nil
      @row_count = 0
      @row_index = 1
      fire_event :import_failed, e
    end

    def fetch_model_block
      self.class.send(:fetch_model_block)
    end

    def fetch_model
      if fetch_model_block
        self.instance_exec(&fetch_model_block)
      else
        model_class.new
      end
    end

    def import
      return if @book.nil?
      fire_event :import_started
      @data_row_indices.each do |index|
        @row_index = index
        @row = row_to_hash @book.row(index)
        if skip_row?
          fire_event :row_skipped
          next
        end
        import_row
        if aborted?
          fire_event :import_aborted, @abort_message
          break
        end
      end
      fire_event :import_finished
    end

    def row_processed_count
      row_index - @header_index
    rescue
      0
    end

    def row_success_count
      row_processed_count - row_errors.count
    end

    def row_error_count
      row_errors.count
    end

    private

    def columns
      self.class.columns
    end

    def skip_row?
      block = self.class.skip_rows_block
      block && self.instance_exec(&block)
    end

    def load_sheet
      sheet_index = self.class.instance_variable_get(:@sheet_index)
      if sheet_index
        sheet_index = @book.sheets[sheet_index-1] if sheet_index.is_a?(Fixnum)
        @book.default_sheet = sheet_index.to_s
      end
    end

    def find_header_index
      (1..@book.last_row).each do |index|
        row = @book.row(index).map { |cell| cell.to_s.strip }
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
        model.save! unless aborted?
      rescue => e
        @row_errors << { row_index: row_index, error_message: e.message }
        fire_event :row_error, e
        return false
      end
      fire_event :row_success
      true
    ensure
      fire_event :row_processed
    end

    def build_model
      row.each_pair do |key, value|
        column_def = columns[key]
        next if column_def.nil? || column_def[:field_name].nil?
        field_name = column_def[:field_name]
        transform = column_def[:transform]
        value = self.instance_exec(value, &transform) if transform
        model.send("#{field_name}=", value)
      end
      fire_event :row_processing
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

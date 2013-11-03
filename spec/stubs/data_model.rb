class DataModel
  @@count = 0

  def self.count
    @@count
  end

  attr_reader :errors

  def initialize(attributes = {})
    @new_record = true
    @errors = []
    attributes.each_pair do |key, value|
      self[key] = value
    end
  end

  def []=(field, value)
    send("#{field}=", value)
  end

  def to_s
    "#{self.class.name}(#{attributes})"
  end

  def save
    if valid?
      @@count += 1 if @new_record
      @new_record = false
      true
    else
      false
    end
  end

  def save!
    raise 'Invalid model' unless save
  end

  def new_record?
    @new_record
  end

  def valid?
    validate
    @errors.empty?
  end

  def validate
    # ...
  end
end

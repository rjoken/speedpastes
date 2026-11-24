class SafeTextValidator < ActiveModel::EachValidator
  def self.error_for(value)
    case value
    when Hash
      error_for(value.to_a)
    when Array
      value.lazy.filter_map { |nested| error_for(nested) }.first
    when String
      value = value.dup.force_encoding(Encoding::UTF_8) if value.encoding == Encoding::BINARY

      if !value.valid_encoding?
        "must be valid UTF-8"
      elsif value.include?("\0")
        "must not contain null bytes"
      end
    end
  end

  def validate_each(record, attribute, value)
    error = self.class.error_for(value)
    record.errors.add(attribute, error) if error
  end
end

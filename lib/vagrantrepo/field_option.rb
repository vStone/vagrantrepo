require 'slop'

module Slop
  # Implements a field option which results in a hash.
  class FieldOption < Option
    def call(value)
      @value ||= {}
      @value.update(split_fields(value, delimiter))
    end

    def default_value
      config[:default] || {}
    end

    def delimiter
      config.fetch(:delimiter, ',')
    end

    def field_separator
      config.fetch(:field_separator, ':')
    end

    private def split_fields(value, field_delimiter = false)
      hash = {}
      if field_delimiter
        split = value.split(field_delimiter)
        split.each do |val|
          hash.update(split_fields(val))
        end
      else
        hash = split_field(value)
      end
      hash
    end

    private def split_field(value)
      Hash[*value.split(field_separator).map(&:strip)]
    end
  end
end

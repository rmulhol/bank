module Bank
  module Serialize
    def self.pack(config, model)
      attrs = model.to_hash

      config.packers.each { |p| p.call(attrs, config) }
      model.set(Serialize.unpack(config, attrs.dup))
      attrs
    end

    def self.unpack(config, attrs)
      config.unpackers.each {|p| p.call(attrs, config) }
      attrs
    end

    PackTimeStamps = ->(attrs, config) do
      now, model = Time.now, config.model.new

      attrs[:updated_at] = now if model.respond_to?(:updated_at=)
      attrs[:created_at] = now if model.respond_to?(:created_at=) &&
        !model.send(config.primary_key)
    end

    PackIntegers = ->(attrs, config) do
      config.columns_of_type(:integer).each { |column, opts|
        attrs[column] = attrs[column].to_i if attrs[column]
      }
    end

    PackBooleans = ->(attrs, config) do
      config.columns_of_type(:boolean).each { |column, opts|
        attrs[column] = attrs[column] ? 1 : 0
      }
    end

    UnpackTime = ->(attrs, config) do
      config.columns_of_type(:datetime).each { |column, opts|
        time = attrs[column]
        attrs[column] = case time
                        when String
                          Time.at(Time.parse(time).to_i)
                        when DateTime
                          Time.at(time.to_time.to_i)
                        else
                          Time.at(time.to_i)
                        end
      }
    end

    UnpackDate = ->(attrs, config) do
      config.columns_of_type(:date).each { |col, _|
          attrs[col] = Date.parse(attrs[col]) if attrs[col].is_a?(String)
      }
    end

    UnpackBoolean = ->(attrs, config) do
      config.columns.select { |col, opts|
        !attrs[col].nil? && opts[:type] == :boolean
      }.each { |col, opts| attrs[col] = [1, true].include?(attrs[col]) }
    end
  end
end

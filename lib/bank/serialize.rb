module Bank
  module Serialize
    def self.pack(*args)
      Packer.new(*args).call
    end

    def self.unpack(*args)
      Unpacker.new(*args).call
    end

    class Packer
      attr_protected :config, :model

      def initialize(config, model)
        self.config = config
        self.model = model
      end

      def call
        attrs = normalize(model.to_hash)

        config.packer.call(attrs)
        set_timestamps(attrs, model)

        model.set(Serialize.unpack(config, attrs.dup))
        attrs
      end

    private

      def set_timestamps(attrs, model)
        now = Time.now

        attrs[:updated_at] = now if model.respond_to?(:updated_at=)
        attrs[:created_at] = now if model.respond_to?(:created_at=) &&
          !model.send(config.primary_key)
      end

      def normalize(attrs)
        attrs = attrs.dup

        of_type(attrs, :integer).each { |column, opts|
          attrs[column] = attrs[column].to_i
        }

        of_type(attrs, :boolean).each { |column, opts|
          attrs[column] = attrs[column] ? 1 : 0
        }

        attrs
      end

      def of_type(attrs, type)
        columns.select { |column, opts|
          !attrs[column].nil? && opts[:type] == type
        }
      end

      def columns
        @columns ||= Bank.db.schema(config.db)
      end
    end

    class Unpacker
      attr_protected :config, :attrs

      def initialize(config, attrs)
        self.config = config
        self.attrs = attrs
      end

      def call
        of_type(:datetime).each { |column, _|
          attrs[column] = drop_usecs(attrs[column])
        }

        of_type(:date).each { |col, _|
          attrs[col] = Date.parse(attrs[col]) if attrs[col].is_a?(String)
        }

        columns.select { |col, opts|
          !attrs[col].nil? && opts[:type] == :boolean
        }.each { |col, opts| attrs[col] = [1, true].include?(attrs[col]) }

        config.unpacker.call(attrs)

        attrs
      end

      def drop_usecs(time)
        case time
        when String
          Time.at(Time.parse(time).to_i)
        when DateTime
          Time.at(time.to_time.to_i)
        else
          Time.at(time.to_i)
        end
      end

      def columns
        @columns ||= Bank.db.schema(config.db)
      end

      def of_type(type)
        columns.select { |col, opts|
          opts[:type] == type && ![nil, 0].include?(attrs[col])
        }
      end
    end

  end
end

module Depository
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

        columns.select { |column, opts|
          !attrs[column].nil? && opts[:type] == :integer
        }.each { |column, opts| attrs[column] = attrs[column].to_i }

        columns.select { |column, opts|
          !attrs[column].nil? && opts[:type] == :boolean
        }.each { |column, opts| attrs[column] = attrs[column] ? 1 : 0 }

        attrs
      end

      def columns
        @columns ||= Depository::Database.db.schema(config.db)
      end
    end

    class Unpacker
      attr_protected :config, :attrs

      def initialize(config, attrs)
        self.config = config
        self.attrs = attrs
      end

      def call
        columns.select { |column, opts|
          opts[:type] == :datetime && ![nil, 0].include?(attrs[column])
        }.each { |column, opts| attrs[column] = drop_usecs(attrs[column]) }

        columns.select { |column, opts|
          opts[:type] == :date && ![nil, 0].include?(attrs[column])
        }.each { |column, opts|
          attrs[column] = Date.parse(attrs[column]) if attrs[column].is_a?(String)
        }

        columns.select { |column, opts|
          !attrs[column].nil? && opts[:type] == :boolean
        }.each { |column, opts| attrs[column] = [1, true].include?(attrs[column]) }

        config.unpacker.call(attrs)
        attrs
      end

      def drop_usecs(time)
        if time.is_a?(String)
          Time.at(Time.parse(time).to_i)
        elsif time.is_a?(DateTime)
          Time.at(time.to_time.to_i)
        else
          Time.at(time.to_i)
        end
      end

      def columns
        @columns ||= Depository::Database.db.schema(config.db)
      end
    end

  end
end

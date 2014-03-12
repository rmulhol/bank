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

        Depository::Database.db.schema(config.db).reject { |column, opts|
          attrs[column].nil? || opts[:type] != :integer
        }.each { |column, opts| attrs[column] = attrs[column].to_i }

        attrs
      end
    end

    class Unpacker
      attr_protected :config, :attrs

      def initialize(config, attrs)
        self.config = config
        self.attrs = attrs
      end

      def call
        config.unpacker.call(attrs)
        attrs
      end
    end

  end
end

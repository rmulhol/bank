require 'attr_protected'
require 'forwardable'

require 'depository/sequel'
require 'depository/collection_config'

module Depository
  RecordNotFound        = Class.new(RuntimeError)
  UnknownConversionType = Class.new(RuntimeError)

  class Collection
    class << self
      extend Forwardable

      def_delegators :db, *DatasetMethods

      def config
        @_config ||= CollectionConfig.new
      end

      def db
        Result.new(config.db, self)
      end

      def scope(name, blk)
        define_singleton_method(name) { |*args| instance_exec *args, &blk }
      end

      def find_by(key, value)
        where(key => value).first
      end

      def save(model)
        if model.send(config.primary_key)
          model.updated_at = Time.now if model.respond_to?(:updated_at=)

          db.where(config.primary_key => model.send(config.primary_key)).
            update(pack(model.to_hash))
        else
          time = Time.now

          [:created_at=, :updated_at=].each do |stamp|
             model.send(stamp, time) if model.respond_to?(stamp)
          end

          model.send(:"#{config.primary_key}=", db.insert(pack(model.to_hash)))
        end

        return model
      end

      def create(attrs)
        save(config.model.new(attrs))
      end

      def update(*args, &blk)
        model = find(*args)

        blk.call(model)
        save(model)
        model
      end

      def find(key)
        result = key.nil? ? nil : where(config.primary_key => key).first

        raise RecordNotFound,
          "no record found in collection with id `#{key.inspect}'" if result.nil?

        return result
      end

      def delete(key)
        db.where(config.primary_key => key).delete
      end

      def convert(attrs)
        case attrs
        when Array
          attrs.map(&method(:convert))
        when Hash
          config.model.new(unpack(attrs))
        else
          raise UnknownConversionType, "unable to convert #{attrs.inspect}"
        end
      end

      def pack(attrs)
        config.packer.call(attrs)
        attrs
      end

      def unpack(attrs)
        config.unpacker.call(attrs)
        attrs
      end
    end
  end
end

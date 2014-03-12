require 'attr_protected'
require 'forwardable'

require 'depository/sequel'
require 'depository/collection_config'
require 'depository/serialize'

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
        pkey = config.primary_key

        if new?(model)
          model.send(:"#{pkey}=", db.insert(Serialize.pack(config, model)))
        else
          db.where(pkey => model.send(pkey)).
            update(Serialize.pack(config, model))
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
          config.model.new(Serialize.unpack(config, attrs))
        else
          raise UnknownConversionType, "unable to convert #{attrs.inspect}"
        end
      end

      def join_as(table, *args, &blk)
        select(*config.model._fields.map { |f| :"#{table}__#{f}"}).join(*args, &blk)
      end

    private

      def new?(model)
        model.send(config.primary_key).nil?
      end
    end
  end
end

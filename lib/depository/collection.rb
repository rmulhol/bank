require 'attr_protected'
require 'forwardable'

require 'depository/sequel'

module Depository
  RecordNotFound        = Class.new(StandardError)
  UnknownConversionType = Class.new(StandardError)

  class CollectionConfig
    attr_protected :_model_block

    def model(&block)
      if block_given?
        self._model_block = block
      else
        @_model ||= _model_block.call
      end
    end

    def db(value = nil)
      if value
        @_db = value.is_a?(Symbol) ? Database[value] : value
      else
        @_db
      end
    end

    def primary_key(value = nil)
      if value
        @_primary_key = value
      else
        @_primary_key ||= :id
      end
    end
  end

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

      def save(model)
        if model.send(config.primary_key)
          update(model.to_hash)
        else
          model.send(:"#{config.primary_key}=", insert(model.to_hash))
          return model
        end
      end

      def find(key)
        result = where(config.primary_key => key).first
        return result if !result.nil?
        raise RecordNotFound,
          "no record found in collection with id `#{key}'"
      end

      def delete(key)
        db.where(config.primary_key => key).delete
      end

      def convert(attrs)
        case attrs
        when Array
          attrs.map(&method(:convert))
        when Hash
          config.model.new(attrs)
        else
          raise UnknownConversionType, "unable to convert #{attrs.inspect}"
        end
      end
    end
  end
end

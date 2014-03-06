require 'attr_protected'
require 'forwardable'

require 'depository/sequel'

module Depository
  RecordNotFound        = Class.new(StandardError)
  UnknownConversionType = Class.new(StandardError)

  class Collection
    class << self
      attr_protected :_model_block, :_model_class, :_db_name

      extend Forwardable

      def_delegators :db, *DatasetMethods

      def use_model(&block)
        self._model_block = block
      end

      def _model
        self._model_class ||= _model_block.call
      end

      def use_db(db_name)
        self._db_name = db_name
      end

      def db
        Depository::Database.db_for(self)
      end

      def primary_key
        @_primary_key ||= :id
      end

      def primary_key=(key)
        @_primary_key = key
      end

      def save(model)
        if model.send(primary_key)
          update(model.to_hash)
        else
          model.send(:"#{primary_key}=", insert(model.to_hash))
          return model
        end
      end

      def find(key)
        result = where(primary_key => key).first
        return result if !result.nil?
        raise RecordNotFound,
          "no record found in collection `#{_db_name}' with id `#{key}'"
      end

      def delete(key)
        db.where(primary_key => key).delete
      end

      def count
        db.raw.size
      end

      def convert(attrs)
        case attrs
        when Array
          attrs.map(&method(:convert))
        when Hash
          _model.new(attrs)
        else
          raise UnknownConversionType, "unable to convert #{attrs.inspect}"
        end
      end
    end
  end
end

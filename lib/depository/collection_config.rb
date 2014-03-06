require 'attr_protected'
require 'depository/database'

module Depository
  class CollectionConfig
    attr_protected :_model_block

    def model(&block)
      if block_given?
        self._model_block = block
      else
        @_model ||= _model_block.call
      end
    end

    def db(&block)
      if block_given?
        @_db_block = block
        @_db = nil
      else
        value = @_db_block.call
        @_db ||= value.is_a?(Symbol) ? Database[value] : value
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
end

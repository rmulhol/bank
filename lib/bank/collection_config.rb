require 'attr_protected'
require 'bank/database'

module Bank
  class CollectionConfig
    attr_protected :_model_block
    attr_writer :packer, :unpacker

    def model(&block)
      if block_given?
        self._model_block = block
      else
        @_model ||= _model_block.call
      end
    end

    def packer
      @packer ||= identity
    end

    def unpacker
      @unpacker ||= identity
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

  private

    def identity
      ->(i) { i }
    end
  end
end

require 'attr_protected'

module Bank
  class CollectionConfig
    attr_protected :_model_block
    attr_writer :packer, :unpacker

    IDENTITY = ->(i) { i }

    def model(&block)
      block_given? ? self._model_block = block : @_model ||= _model_block.call
    end

    def packer
      @packer ||= IDENTITY
    end

    def unpacker
      @unpacker ||= IDENTITY
    end

    def db(&block)
      if block_given?
        @_db_block = block
        @_db = nil
      else
        value = @_db_block.call
        @_db ||= value.is_a?(Symbol) ? Bank[value] : value
      end
    end

    def primary_key(value = nil)
      value ?  @_primary_key = value : @_primary_key ||= :id
    end
  end
end

require 'attr_protected'

module Bank
  class CollectionConfig
    attr_protected :_model_block, :_packers, :_unpackers

    IDENTITY = ->(i) { i }

    def model(&block)
      block_given? ? self._model_block = block : @_model ||= _model_block.call
    end

    def packer(blk)   packers << blk   end
    def unpacker(blk) unpackers << blk end

    def packers
      @_packers ||= Bank.config.default_packers
    end

    def unpackers
      @_unpackers ||= Bank.config.default_unpackers
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

    def columns
      @_columns ||= Bank.db.schema(db)
    end

    def columns_of_type(type)
      columns.select { |col, opts| opts[:type] == type }
    end
  end
end

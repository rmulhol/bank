require 'attr_protected'

module Bank
  class Model
    class Config
      attr_protected :_fields, :_defaults, :_model

      def initialize(model)
        self._model = model
        self._fields = []
        self._defaults = {}
      end

      def fields(*fields)
        self._fields = fields
        _model.send(:attr_accessor, *fields)
      end

      def defaults(defaults = {})
        self._defaults = defaults
      end
    end

    def self.included(base)
      base.define_singleton_method(:config) do
        @_config ||= Bank::Model::Config.new(self)
      end
    end

    def initialize(attrs = {})
      set(attrs)
      _defaults.reject { |key, _| get(key) }.each { |key, val| set(key, val) }
    end

    def to_hash
      _fields.reduce({}) do |acc, field|
        acc.merge(field => get(field))
      end
    end

    def get(attr)
      instance_variable_get(:"@#{attr}")
    end

    def set(attr, value = nil)
      if attr.is_a?(Hash)
        attr.each { |key, value| set(key, value) }
      else
        public_send(:"#{attr}=", value)
      end

      return self
    end

    def ==(other)
      other.is_a?(self.class) && other.to_hash == to_hash
    end

    private

    def _fields
      self.class.config._fields
    end

    def _defaults
      self.class.config._defaults
    end
  end
end

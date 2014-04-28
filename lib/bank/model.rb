require 'attr_protected'

module Bank
  class Model
    class << self
      attr_protected :_fields, :_defaults

      def fields(*fields)
        attr_accessor *fields
        self._fields = fields
      end

      def _fields
        @_fields ||= []
      end

      def defaults(defaults)
        self._defaults = defaults
      end

      def _defaults
        @_defaults ||= {}
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
      self.class._fields
    end

    def _defaults
      self.class._defaults
    end
  end
end

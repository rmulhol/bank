require 'attr_protected'
require 'bank/model'
require 'bank/collection'
require 'bank/result'
require 'bank/config'

module Bank
  class << self
    attr_protected :_config, :db

    def use_db(db)
      self.db = db
    end

    def [](name)
      self.db[name]
    end

    def config
      self._config ||= Bank::Config.new
    end
  end
end

require 'attr_protected'
require 'bank/model'
require 'bank/collection'
require 'bank/result'

module Bank
  class << self
    attr_protected :db

    def use_db(db)
      self.db = db
    end

    def [](name)
      self.db[name]
    end
  end
end

require 'attr_protected'

require 'bank/result'

module Bank
  class Database
    class << self
      attr_protected :db

      def self.db
        db.dup
      end

      def use_db(db)
        self.db = db
      end

      def [](name)
        self.db[name]
      end
    end
  end
end

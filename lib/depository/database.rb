require 'attr_protected'

require 'depository/result'

module Depository
  class Database
    class << self
      attr_protected :db

      def use_db(db)
        self.db = db
      end

      def db_for(collection)
        Result.new(self.db[collection._db_name], collection)
      end
    end
  end
end

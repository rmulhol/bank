require 'attr_protected'
require 'forwardable'

require 'depository/sequel'

module Depository
  class Result
    include Enumerable
    extend Forwardable

    attr_protected :db, :collection

    def_delegators :db, *[:update, :insert, :delete, :max, :min, :count]
    def_delegators :all, :inspect, :empty?

    def initialize(db, collection)
      self.db = db
      self.collection = collection
    end

    def each(&blk)
      raw.each { |result| blk.call(collection.convert(result)) }
    end

    def raw
      db.all
    end

    def all
      collection.convert(raw)
    end

    # db overrides for Enumerable-clashing methods
    def select(*args, &block)   new(db.select(*args, &block)) end
    def group_by(*args, &block) new(db.group_by(*args, &block)) end
    def grep(*args, &block)     new(db.grep(*args, &block)) end

    def method_missing(*args, &blk)
      DatasetMethods.include?(args[0]) ? new(db.send(*args, &blk)) : super
    end

    def respond_to?(method)
      DatasetMethods.include?(method) || super
    end

    def ==(other)
      self.all == other
    end
    alias_method :eql?, :==

    def inspect
      all.inspect
    end

  private

    def new(db)
      self.class.new(db, collection)
    end
  end
end

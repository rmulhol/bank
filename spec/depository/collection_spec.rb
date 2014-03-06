require 'sequel'

require 'depository/database'
require 'depository/collection'
require 'depository/model'

describe Depository::Collection do
  let(:collection) { Class.new(Depository::Collection) }
  let(:model) { Class.new(Depository::Model) { fields :name, :age, :id }}
  let(:db) { Sequel.sqlite }

  before do
    db.create_table :people do
      primary_key :id

      String :name
      Integer :age
    end

    db.create_table :pets do
      primary_key :id

      String :name
    end

    db.create_table :people_pets do
      Integer :person_id
      Integer :pet_id
    end

    Depository::Database.use_db(db)
    collection.use_model { model }
    collection.use_db :people
  end

  it "saves a model" do
    saved_model = collection.save(model.new(:name => "a-name"))
    saved_model.id.should_not be_nil
  end

  it "updates a previously saved model" do
    saved_model = collection.save(model.new(:name => "a-name"))
    saved_model.name = "new-name"

    expect {
      collection.save(saved_model)
    }.not_to change { collection.count }

    collection.find(saved_model.id).name.should == "new-name"
  end

  describe "querying" do
    let!(:saved_model) { collection.save(model.new(:name => "a-name", :age => 42)) }
    let!(:saved_model2) { collection.save(model.new(:name => "diff-name", :age => 22)) }

    describe "#find" do
      it "finds a model class by key" do
        collection.find(saved_model.id).should == saved_model
        collection.find(saved_model2.id).should == saved_model2
      end

      it "raises RecordNotFound if the record does not exist" do
        expect {
          collection.find("some-key")
        }.to raise_error(Depository::RecordNotFound)
      end
    end

    it "WHERE clauses" do
      collection.where(:name => saved_model2.name).should == [saved_model2]

      collection.where(:name => saved_model2.name).
        where(:age => 22).should == [saved_model2]
    end

    it "contains (most) enumerable methods (minus select, group_by, grep)" do
      collection.where(:name => "a-name").map(&:name).should == ["a-name"]
      collection.where(:name => "a-name").reduce(0) { |age, p| age += p.age }.
        should == 42
    end

    it "#raw gives a list/hashes result (skip conversion, e.g. for joins)" do
      pet_id = db[:pets].insert(:name => "Doggie")

      db[:people_pets].insert(
        :person_id => saved_model.id,
        :pet_id => pet_id
      )

      result = collection.
        select(:people__name, :people__age, :pets__name___pet_name).
        join(:pets, :people_pets__pet_id => :pets__id).
        join(:people_pets, :person_id => :people__id).
        where(:people__id => saved_model.id).
        raw.
        first

      result[:name].should     == saved_model.name
      result[:age].should      == saved_model.age
      result[:pet_name].should == "Doggie"
    end
  end

  describe "delete" do
    it "removes the record from the database" do
      saved_model = collection.save(model.new(:name => "a-name"))

      expect {
        collection.delete(saved_model.id)
      }.to change { collection.count }.by(-1)

      expect {
        collection.find(saved_model.id)
      }.to raise_error(Depository::RecordNotFound)
    end
  end

  describe "order" do
    it "retrieves models in the order provided" do
      three = collection.save(model.new(:age => 3))
      two = collection.save(model.new(:age => 2))
      one = collection.save(model.new(:age => 1))

      collection.where { id < 5 }.order(:age).should == [one, two, three]
      collection.where { id < 5 }.order(Sequel.desc(:age)).should == [
        three, two, one
      ]
    end
  end

  describe "max" do
    it "returns top value in result-set for given column" do
      three = collection.save(model.new(:age => 3))
      two = collection.save(model.new(:age => 2))
      one = collection.save(model.new(:age => 1))

      collection.where { age < 3 }.max(:age).should == 2
      collection.max(:age).should == 3
    end
  end

  describe "limit" do
    it "constrains results to the first n records" do
      results = (1...10).to_a.map do |num|
        collection.save(model.new(:age => num))
      end

      collection.order(:age).limit(5).should == results.take(5)
    end
  end
end

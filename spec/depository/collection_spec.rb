require 'sequel'
require 'yaml'

require 'depository/database'
require 'depository/collection'
require 'depository/model'

describe Depository::Collection do
  model = Class.new(Depository::Model) {
    fields :name, :age, :id, :hash, :created_at, :updated_at
    defaults :hash => {}
  }

  let(:collection) {
    Class.new(Depository::Collection) do
      config.db { :people }
      config.model { model }
      config.primary_key :id

      config.packer = ->(attrs) {
        attrs[:hash] = YAML.dump(attrs.fetch(:hash, {}))
      }

      config.unpacker = ->(attrs) {
        attrs[:hash] = YAML.load(attrs.fetch(:hash, ""))
      }
    end
  }

  let(:db) { Sequel.sqlite }

  before do
    db.create_table :people do
      primary_key :id

      String :name
      String :hash, :text => true
      Integer :age

      DateTime :created_at
      DateTime :updated_at
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
  end

  describe "save" do
    it "saves a new model" do
      saved_model = collection.save(model.new(:name => "a-name"))
      saved_model.id.should_not be_nil
      saved_model.hash.should == {}
    end

    it "sets a created_at on create" do
      now = Time.now
      Time.stub(:now) { now }

      saved_model = collection.create(:name => "a-name")
      saved_model.created_at.should == now
    end

    it "saves a previously saved model" do
      saved_model = collection.save(model.new(:name => "a-name"))
      saved_model.name = "new-name"

      expect {
        collection.save(saved_model)
      }.not_to change { collection.count }

      collection.find(saved_model.id).name.should == "new-name"
    end

    it "sets updated_at on save" do
      now = Time.now
      Time.stub(:now) { now }

      saved_model = collection.create(:name => "a-name")
      saved_model.created_at.should == now

      saved_model.name = "new-name"
      collection.save(saved_model)

      saved_model.updated_at.should == now
    end
  end

  describe "db" do
    it "uses the db set in the config" do
      mock_db = double.as_null_object
      collection.config.db { mock_db }
      collection.config.db.should == mock_db
    end

    it "can use a scoped dataset as db" do
      unscoped_model = collection.save(model.new(:name => "another-name"))
      collection.config.db { Depository::Database[:people].where(:name => "a-name") }

      saved_model = collection.save(model.new(:name => "a-name"))

      collection.find(saved_model.id).should == saved_model

      expect {
        collection.find(unscoped_model.id)
      }.to raise_error(Depository::RecordNotFound)
    end
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

      it "raises RecordNotFound if the key is nil" do
        expect {
          collection.find(nil)
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

  describe "scope" do
    it "creates a method on the collection" do
      person = collection.create(:age => 42)
      collection.scope :aged, ->(age) { where(:age => age) }

      collection.aged(42).should == [person]
    end
  end

  describe "find_by" do
    it "returns the first result for matching records" do
      person = collection.create(:name => "name")
      person2 = collection.create(:name => "name")

      collection.find_by(:name, "name").should == person
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

  describe "update" do
    it "updates the correct model" do
      saved = collection.create(:name => "first-name")
      collection.update(saved.id) do |model|
        model.should == saved
        model.name = "second-name"
      end

      collection.find(saved.id).name.should == "second-name"
    end
  end

  describe "packer" do
    it "packs/unpacks models before save/after load" do
      saved = collection.create(:hash => { :one => 'two' })
      collection.find(saved.id).hash.should == { :one => 'two' }
    end
  end
end

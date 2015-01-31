require 'sequel/core'
require 'yaml'

require 'bank/bank'

describe Bank, "Acceptance" do
  model = Class.new do
    include Bank::Model

    config.fields :name, :age, :id, :verified, :hash, :created_at, :updated_at
    config.defaults :hash => {}
  end

  before(:all) do
    db = Sequel.connect('do:sqlite3::memory:')

    db.create_table :people do
      primary_key :id

      String :name
      String :hash, :text => true
      Integer :age
      Boolean :verified

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

    Bank.use_db(db)
  end

  let(:collection) {
    Class.new do
      extend Bank::Collection

      config.db { :people }
      config.model { model }
      config.primary_key :id

      config.packer ->(attrs, config) {
        attrs[:hash] = YAML.dump(attrs.fetch(:hash, {}))
      }

      config.unpacker ->(attrs, config) {
        attrs[:hash] = YAML.load(attrs.fetch(:hash, ""))
      }
    end
  }

  before do
    [:people, :pets, :people_pets].each { |table| Bank.db[table].delete }
  end

  describe "save" do
    it "saves a new model" do
      saved_model = collection.save(model.new(:name => "a-name"))
      expect(saved_model.id).not_to be_nil
      expect(saved_model.hash).to eq({})
    end

    it "coerces string params to integers if need be" do
      saved_model = collection.create(:age => "50")

      expect(saved_model.age).to be_a(Integer)
      expect(saved_model.age).to eq 50
    end

    it "sets a created_at on create" do
      now = Time.at(Time.now.to_i)
      Time.stub(:now) { now }

      saved_model = collection.create(:name => "a-name")
      expect(saved_model.created_at).to eq now
    end

    it "saves a previously saved model" do
      saved_model = collection.save(model.new(:name => "a-name"))
      saved_model.name = "new-name"

      expect {
        collection.save(saved_model)
      }.not_to change { collection.count }

      expect(collection.find(saved_model.id).name).to eq "new-name"
    end

    it "sets updated_at on save" do
      now = Time.at(Time.now.to_i)
      Time.stub(:now) { now }

      saved_model = collection.create(:name => "a-name")
      expect(saved_model.created_at).to eq now

      saved_model.name = "new-name"
      collection.save(saved_model)

      expect(saved_model.updated_at).to eq now
    end
  end

  describe "db" do
    it "uses the db set in the config" do
      mock_db = double.as_null_object
      collection.config.db { mock_db }
      expect(collection.config.db).to eq mock_db
    end

    it "can use a scoped dataset as db" do
      unscoped_model = collection.save(model.new(:name => "another-name"))
      collection.config.db { Bank[:people].where(:name => "a-name") }

      saved_model = collection.save(model.new(:name => "a-name"))

      expect(collection.find(saved_model.id)).to eq saved_model

      expect {
        collection.find(unscoped_model.id)
      }.to raise_error(Bank::RecordNotFound)
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
        }.to raise_error(Bank::RecordNotFound)
      end

      it "raises RecordNotFound if the key is nil" do
        expect {
          collection.find(nil)
        }.to raise_error(Bank::RecordNotFound)
      end
    end

    it "WHERE clauses" do
      expect(collection.where(:name => saved_model2.name)).to eq [saved_model2]

      expect(collection.where(:name => saved_model2.name).
        where(:age => 22)).to eq [saved_model2]
    end

    it "contains (most) enumerable methods (minus select, group_by, grep)" do
      expect(collection.where(:name => "a-name").map(&:name)).to eq ["a-name"]
      expect(collection.where(:name => "a-name").reduce(0) { |age, p| age += p.age }).
        to eq 42
    end

    it "#raw gives a list/hashes result (skip conversion, e.g. for joins)" do
      pet_id = Bank.db[:pets].insert(:name => "Doggie")

      Bank.db[:people_pets].insert(
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

      expect(result[:name]).to     eq saved_model.name
      expect(result[:age]).to      eq saved_model.age
      expect(result[:pet_name]).to eq "Doggie"
    end
  end

  describe "find_by" do
    it "returns the first result for matching records" do
      person = collection.create(:name => "name")
      person2 = collection.create(:name => "name")

      expect(collection.find_by(:name, "name")).to eq person
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
      }.to raise_error(Bank::RecordNotFound)
    end
  end

  describe "update" do
    it "updates the correct model" do
      saved = collection.create(:name => "first-name")
      collection.update(saved.id) do |model|
        model.should eq saved
        model.name = "second-name"
      end

      expect(collection.find(saved.id).name).to eq "second-name"
    end
  end

  describe "packer" do
    it "packs/unpacks models before save/after load" do
      saved = collection.create(:hash => { :one => 'two' })
      expect(collection.find(saved.id).hash).to eq :one => 'two'
    end

    it "converts booleans" do
      falsey = collection.create(:verified => false)
      expect(collection.find(falsey.id).verified).to be_falsey

      truthy = collection.create(:verified => true)
      expect(collection.find(truthy.id).verified).to be_truthy
    end

  end
end

require 'depository/model'

describe Depository::Model do
  let(:model_class) do
    Class.new(Depository::Model) { fields :name, :age }
  end

  it "has a list of fields" do
    model_class._fields.should == [:name, :age]
  end

  it "sets attributes passed in on instantiation" do
    model_class.new(:name => "name").name.should == "name"
  end

  it "#get gets an attribute" do
    model_class.new(:name => "name").get(:name).should == "name"
  end

  it "#set sets an attribute" do
    person = model_class.new(:name => "name")
    person.set(:name, "new-name")
    person.name.should == "new-name"
  end

  it "#set with a hash sets many attributes" do
    person = model_class.new(:name => "name")
    person.set(:name => "new-name", :age => 365)

    person.name.should == "new-name"
    person.age.should == 365
  end

  it "#to_hash exports attributes to hash" do
    person = model_class.new(:name => "name", :age => 42)
    person.to_hash.should == {
      :name => "name",
      :age => 42
    }
  end

  it "#to_hash excludes unset attributes" do
    person = model_class.new(:name => "name")
    person.to_hash.should == { :name => "name" }
  end

  it "is equal to other objects of the same type with the same attributes" do
    person1 = model_class.new(:name => "name", :age => 42)
    person2 = model_class.new(:name => "name", :age => 42)
    diff_person = model_class.new(:name => "diff-name", :age => 42)

    person1.should     == person2
    person1.should_not == diff_person
  end

  it "defines default values" do
    model_class.defaults(:name => "default-name")
    model_class.new(:age => 42).name.should == "default-name"
  end
end

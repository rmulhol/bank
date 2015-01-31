require 'bank/model'

describe Bank::Model do

  let(:model_class) do
    Class.new {
      include Bank::Model

      config.fields :name, :age
    }
  end

  it "has a list of fields" do
    expect(model_class.config._fields).to eq [:name, :age]
  end

  it "sets attributes passed in on instantiation" do
    expect(model_class.new(:name => "name").name).to eq "name"
  end

  it "#get gets an attribute" do
    expect(model_class.new(:name => "name").get(:name)).to eq "name"
  end

  it "#set sets an attribute" do
    person = model_class.new(:name => "name")
    person.set(:name, "new-name")
    expect(person.name).to eq "new-name"
  end

  it "#set with a hash sets many attributes" do
    person = model_class.new(:name => "name")
    person.set(:name => "new-name", :age => 365)

    expect(person.name).to eq "new-name"
    expect(person.age).to eq 365
  end

  it "#to_hash exports attributes to hash" do
    person = model_class.new(:name => "name", :age => 42)
    expect(person.to_hash).to eq(
      :name => "name",
      :age => 42
    )
  end

  it "is equal to other objects of the same type with the same attributes" do
    person1 = model_class.new(:name => "name", :age => 42)
    person2 = model_class.new(:name => "name", :age => 42)
    diff_person = model_class.new(:name => "diff-name", :age => 42)

    expect(person1).to eq person2
    expect(person1).not_to eq diff_person
  end

  it "defines default values" do
    model_class.config.defaults(:name => "default-name")
    expect(model_class.new(:age => 42).name).to eq "default-name"
  end

end

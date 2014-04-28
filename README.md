# Bank

Bank is an experimental attempt at wrapping [Sequel](http://sequel.jeremyevans.net)
with a simple data-mapping layer, without going all the way into a full-on,
ActiveRecord-like ORM.

Currently plays nice with [Data Objects](https://github.com/datamapper/do) backends.

For a quick-start example, check out the acceptance specs.

## Collections

Collections represent the interface to your datastore. You might think of them as
"repositories." A collection will save a model and query for it as well. Collections
wrap the [Sequel query interface](http://sequel.jeremyevans.net/rdoc/files/doc/querying_rdoc.html)
to lazily build up dataset results, only executing the query and returning a result
when it is necessary.

```ruby
class UsersCollection
  extend Bank::Collection

  config.model { User }
  config.db    { :users }

  def self.find_by_email(email)
    where(:email => email)
  end
end

```

Apart from the Sequel query methods, Collections implement the following methods as syntactic sugar:
* `save` persist (either an `INSERT` or `UPDATE` operation) the given model
* `find` look up a single record by primary key
* `find_by` look up a single record by the given key and value
* `create` initialize and save a model with the given attributes
* `delete` delete the record with the given primary key
* `update` look up a record with the given primary key, which is passed into a block and
  saved after the block has finished executing.

```ruby
MyCollection.update(key) { |model| model.name = "new-name" }
```

Collection results implement the Enumerable interface, and so respond to
`map`,`each`, etc., just as you'd expect an array to respond.

### Configuration

* `db` can be a symbol that points to a table in your database schema,
  or a `Sequel::Dataset` that represents a scoped set of results.
* `model` is the model class that Bank will serialize your results to.
  Defaults to `Hash`
* `primary_key` is the column Bank will use to look up results. Defaults to `:id`

### Scopes
WIP. The idea is that scopes are chain-able, user-defined, small bits of queries.
It doesn't work yet, so don't use 'em yet.

### Serialization
Collections can be configured to serialize and deserialize data with the use of
`packer` and `unpacker` objects. Simply, these objects must respond to `call`,
and take a single argument: the hash of attributes. They can be defined as a simple
lambda, or as a more advanced user-defined object if necessary.

Packers and unpackers are evaluated prior to model conversion.

Example: serializing and deserializing a hash from JSON.

```ruby
class AuditsCollection
  extend Bank::Collection

  config.packer   ->(attrs) { attrs[:a_hash] = attrs[:a_hash].to_json }
  config.unpacker ->(attrs) { attrs[:a_hash] = JSON.parse(attrs[:a_hash]) }
end
```

## Models

Models are simple data structures that serve to represent entities in your
datastore.

### Configuration

Models have a few configuration options:
* `fields` defines the list of columns that are returned from the database
* `defaults` defines a hash of default values for a given field (if a default
  is not provided, the "default" value is `nil`, as is for most instance variables)

```ruby
class User
  include Bank::Model

  config.fields :first_name, :last_name, :email, :age
  config.defaults :age => 42

end
```

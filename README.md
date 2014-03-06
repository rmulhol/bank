# Depository

Depository is an attempt at making database
abstractions seem more real than they are in raw
[Sequel](http://sequel.jeremyevans.net),
without going too far and using a full-on ActiveRecord-style
ORM. This just encapsulates a few of the use-cases I seem
to re-create time and time again when using Sequel.

Currently just experimental. Advantages?
* run tests in-memory with SQLite for speed
* *excellent* query interface courtesy of [Sequel](http://sequel.jeremyevans.net)
* separate persistence/querying of data from application-level behavior

## A Simple Example
*Collections* represent the interface of persistence to your app.
They save and retrieve *Model* objects, which are simple
data-structures that wrap query results.

```ruby
db = Sequel.sqlite # requires 'sqlite3' gem, not included
Depository::Database.use_db(db)

db.create_table(:books) do |table|
  primary_key :id
  String :title
  Integer :author_id
end

class Book < Depository::Model
  fields :id, :title, :author_id
end

class BooksCollection < Depository::Collection
  config.model { MyModel }
  config.db :books  # points to 'books' table created above

  def self.by_author(author)
    where(:author_id => author.id)
  end
end

book = Book.new(:title => 'Book!', :author_id => author.id)

BooksCollection.save(book)
BooksCollection.find(book.id) == book        # => true

BooksCollection.for_author(author) == [book] # => true
```

## Databases
Depository uses a top-level database singleton. You pass it a Sequel DB object,
and any collections are scoped to that database. See the
[Sequel Docs](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)
for more info on creating database connections.

```ruby
Depository::Database.use_db(Sequel.sqlite)

# query the `books' table directly
Depository::Database[:books]
```

## Collections
Collections represent the interface to persistence. They wrap
[Sequel datasets](http://sequel.jeremyevans.net/rdoc/files/doc/dataset_basics_rdoc.html),
which lazily construct queries, and then convert the queries to the configured
model class when the query is evaluated. Collections implement most everything a
Sequel dataset does, plus they contain support for Enumerable.

Beyond that, Collections basically implement only 3 methods:
* `save(model)` - persist a new or existing record to the database
* `find(primary_key)` - fetch a record from the database
* `delete(primary_key)` -  remove a record from the database

### Configuring Collections
Collections are configured with a top-level dataset object, under which all
collection queries are scoped. You can also provide a symbol with the
name of a table, and the Collection will use the corresponding dataset by default.

```ruby
class MyCollection < Depository::Collection
  # use a Sequel dataset directly
  config.db Depository::Database[:books]

  # equivalent: pass a symbol
  config.db :books

  # use a Sequel dataset with a constraint
  config.db Depository::Database[:books].where(:archived => false)
end
```

You can specify a primary_key, which is defaulted to `:id`
```ruby
class MyCollection < Depository::Collection
  config.primary_key :key
end
```

Lastly, you can set a model class that the collection will use
for conversion of results.

```ruby
class MyCollection < Depository::Collection
  config.model { MyModel }
end
```

## Models
Models represent single records returned from a query. They are configured
with a list of fields that correspond to table columns.

```ruby
class Person < Depository::Model
  fields :id, :name, :age

  defaults :age => 42
end

# build a Person object in memory
bob = Person.new(:name => "Bob")
bob.name # => "Bob"
bob.age  # => 42

# get and set attributes conveniently
bob.get(:name) # => "Bob"
bob.set(:name, "JimBob")
bob.get(:name) # => "JimBob"

# represent Bob as a hash
bob.to_hash  # => { :id => 1, :name => "JimBob", :age => 42 }
```

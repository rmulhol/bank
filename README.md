# Depository

Depository is an attempt at making database
abstractions seem more real than they are in raw Sequel,
without going too far and using a full-on ActiveRecord-style
ORM.

Currently just experimental.

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
  use_model { MyModel }
  use_db :books  # points to 'books' table created above

  def self.by_author(author)
    where(:author_id => author.id)
  end
end

book = Book.new(:title => 'Book!', :author_id => author.id)

BooksCollection.save(book)
BooksCollection.find(book.id) == book        # => true

BooksCollection.for_author(author) == [book] # => true
```

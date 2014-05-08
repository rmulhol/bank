$:<< File.join(FileUtils.pwd, "lib")

def with_database(&blk)
  require 'artisan/db/mysql'
  Sequel.extension :migration

  Artisan::Database.connect!

  blk.call(Depository::Database.db)
end

def with_connection(&blk)
  require 'artisan/db/mysql'

  config = Artisan::Database.config
  user = config["user"]
  password = config["password"]
  host = config["host"]

  db = Sequel.connect("do:mysql://#{user}:#{password}@#{host}")
  blk.call(db)
end

namespace :db do
  desc "migrate db to latest"
  task :migrate do
    with_database do |db|
      require 'logger'
      db.loggers << Logger.new($stdout)
      Sequel::Migrator.run(db, "db/migrate")
    end
  end

  desc "drop database"
  task :drop do
    with_connection do |db|
      database = Artisan::Database.config["database"]
      puts "dropping #{database}"
      db.run "drop database `#{database}`"
    end
  end

  desc "create database"
  task :create do
    with_connection do |db|
      database = Artisan::Database.config["database"]
      puts "creating #{database}"
      db.run "create database if not exists `#{database}`"
    end
  end

  desc "'bootstrap' database (create / migrate)"
  task :bootstrap => [:create, :migrate]

  desc "'do-over' database (drop / create / migrate)"
  task :do_over => [:drop, :bootstrap]

  desc "shorthand for 'do_over'"
  task :do => [:do_over]
end

migration_class = ((ActiveRecord.version.to_s.to_i < 5) ? ActiveRecord::Migration : ActiveRecord::Migration[5.0])

class TestMigrationOne < migration_class
  def up
    execute "SELECT 1"
  end

  def down
    execute "SELECT 0"
  end
end

class TestMigrationTwo < migration_class
  def up
    execute "SELECT 1"
    disable_sql_logging do
      execute "SELECT 2"
      enable_sql_logging do
        execute "SELECT 3"
      end
      execute "SELECT 4"
    end
    execute "SELECT 5"
  end
end

class TestMigrationThree < migration_class
  def up
    using_connection(OtherClass.connection, label: "Other database") do
      create_table :test_3, id: false do |t|
        t.integer :value
      end
    end
  end
end

class TestMigrationFour < migration_class
  def up
    using_connection(OtherClass) do
      create_table :test_4, id: false do |t|
        t.integer :value
      end
    end
  end
end

class OtherClass < ActiveRecord::Base
  establish_connection("adapter" => "sqlite3", "database" => ":memory:")
end

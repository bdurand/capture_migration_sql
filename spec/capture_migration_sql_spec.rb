require_relative './spec_helper'

require 'tmpdir'

describe CaptureMigrationSql do
  before :all do
    CaptureMigrationSql.capture(directory: Dir.tmpdir, starting_with: 20170101000000)
  end

  before :each do
    File.unlink(file) if File.exist?(file)
  end

  after :each do
    File.unlink(file) if File.exist?(file)
  end

  let(:version) { 20181008000000 }
  let(:file) { File.join(Dir.tmpdir, "#{version}_#{migration.class.name.underscore}.sql") }
  let(:migration) { TestMigrationOne.new("TestMigrationOne", version) }

  describe "capturing SQL" do
    it "should capture sql to a file when migrating up and remove it when migrating down" do
      expect(File.exist?(file)).to eq false
      migration.migrate(:up)
      expect(File.exist?(file)).to eq true
      expect(File.read(file)).to eq <<~SQL
        --
        -- TestMigrationOne : 20181008000000
        --

        SELECT 1;

        INSERT INTO schema_migrations (version) VALUES ('20181008000000');
      SQL

      migration.migrate(:down)
      expect(File.exist?(file)).to eq false
    end

    context "using migration two" do
      let(:migration) { TestMigrationTwo.new("TestMigrationTwo", version) }

      it "should not capture sql in a blocks where capture is disabled" do
        migration = TestMigrationTwo.new("TestMigrationTwo", version)
        file = File.join(Dir.tmpdir, "#{version}_test_migration_two.sql")
        migration.migrate(:up)
        expect(File.read(file)).to eq <<~SQL
          --
          -- TestMigrationTwo : 20181008000000
          --

          SELECT 1;

          SELECT 3;

          SELECT 5;

          INSERT INTO schema_migrations (version) VALUES ('20181008000000');
        SQL
      end
    end

    context "using earlier version" do
      let(:version) { 20160101000000 }

      it "should not capture sql if the migration version is less than the max specified" do
        migration.migrate(:up)
        expect(File.exist?(file)).to eq false
      end
    end
  end

  describe "database connection" do
    context "using a connection object" do
      let(:migration) { TestMigrationThree.new("TestMigrationThree", version) }

      it "should use a different connection in a block" do
        migration.migrate(:up)
        expect(File.read(file)).to eq <<~SQL
          --
          -- TestMigrationThree : 20181008000000
          --

          -- BEGIN Other database

          CREATE TABLE "test_3" ("value" integer);

          -- END Other database

          INSERT INTO schema_migrations (version) VALUES ('20181008000000');
        SQL

        other_db_exists = OtherClass.connection.select_one("SELECT name FROM sqlite_master WHERE type='table' AND name = 'test_3'")
        main_db_exists = ActiveRecord::Base.connection.select_one("SELECT name FROM sqlite_master WHERE type='table' AND name = 'test_3'")
        expect(other_db_exists).to_not eq nil
        expect(main_db_exists).to eq nil
      end
    end

    context "using an ActiveRecord class" do
      let(:migration) { TestMigrationFour.new("TestMigrationFour", version) }

      it "should use a different class' connection in a block" do
        migration.migrate(:up)
        expect(File.read(file)).to eq <<~SQL
          --
          -- TestMigrationFour : 20181008000000
          --

          -- BEGIN OtherClass

          CREATE TABLE "test_4" ("value" integer);

          -- END OtherClass

          INSERT INTO schema_migrations (version) VALUES ('20181008000000');
        SQL

        other_db_exists = OtherClass.connection.select_one("SELECT name FROM sqlite_master WHERE type='table' AND name = 'test_4'")
        main_db_exists = ActiveRecord::Base.connection.select_one("SELECT name FROM sqlite_master WHERE type='table' AND name = 'test_4'")
        expect(other_db_exists).to_not eq nil
        expect(main_db_exists).to eq nil
      end
    end
  end
end

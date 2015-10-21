describe DataDuck::Table do
  class TestSomeTable < DataDuck::Table; end

  describe "self.source" do

    before(:each) do
      TestSomeTable.sources = []
    end

    it "correctly sources a table with columns" do
      expect(DataDuck::Source).to receive(:source).with(:my_test_db).and_return(:fake_source)
      TestSomeTable.source(:my_test_db, :my_test_table, ['prop1', 'prop2'])
      expect(TestSomeTable.sources.length).to eq(1)
      expect(TestSomeTable.sources[0][:source]).to eq(:fake_source)
      expect(TestSomeTable.sources[0][:columns]).to eq(['prop1', 'prop2'])
      expect(TestSomeTable.sources[0][:table_name]).to eq('my_test_table')
    end

    it "correctly sources a table defined as coming from a query" do
      expect(DataDuck::Source).to receive(:source).with(:my_test_db).and_return(:fake_source)
      TestSomeTable.source(:my_test_db, "SELECT asdf, fdas FROM my_table")
      expect(TestSomeTable.sources.length).to eq(1)
      expect(TestSomeTable.sources[0][:source]).to eq(:fake_source)
      expect(TestSomeTable.sources[0][:query]).to eq("SELECT asdf, fdas FROM my_table")
    end

    it "correctly sources a table without explicitly naming the table" do
      expect(DataDuck::Source).to receive(:source).with(:my_test_db).and_return(:fake_source)
      TestSomeTable.source(:my_test_db, ['prop1', 'prop2'])
      expect(TestSomeTable.sources.length).to eq(1)
      expect(TestSomeTable.sources[0][:source]).to eq(:fake_source)
      expect(TestSomeTable.sources[0][:columns]).to eq(['prop1', 'prop2'])
      expect(TestSomeTable.sources[0][:table_name]).to eq('test_some_table')
    end
  end

  describe "extract_query" do
    it "correctly outputs a normal select sql query" do
      table = TestSomeTable.new
      result = table.extract_query({
          columns: ["id", "created_at", "updated_at", "foo", "bar"],
          table_name: "test_some_table",
          source: DataDuck::Source.new('test', {})
      })

      expect(result).to eq("SELECT bar,created_at,foo,id,updated_at FROM test_some_table")
    end

    it "correctly outputs a normal select sql query for mysql dbs" do
      table = TestSomeTable.new
      result = table.extract_query({
              columns: ["id", "created_at", "updated_at", "foo", "bar"],
              table_name: "test_some_table",
              source: DataDuck::MysqlSource.new('test', {})
          })

      expect(result).to eq("SELECT `bar`,`created_at`,`foo`,`id`,`updated_at` FROM test_some_table")
    end

    it "correctly outputs a normal select sql query for postgresql dbs" do
      table = TestSomeTable.new
      result = table.extract_query({
              columns: ["id", "created_at", "updated_at", "foo", "bar"],
              table_name: "test_some_table",
              source: DataDuck::PostgresqlSource.new('test', {})
          })

      expect(result).to eq("SELECT \"bar\",\"created_at\",\"foo\",\"id\",\"updated_at\" FROM test_some_table")
    end
  end
end

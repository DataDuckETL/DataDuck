describe DataDuck::Table do
  describe "self.source" do
    class TestSomeTable < DataDuck::Table; end

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
end

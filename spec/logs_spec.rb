describe DataDuck::Logs do
  describe "sanitize_message" do
    it "removes aws secrets" do
      expect(DataDuck::Logs.sanitize_message("COPY zz_dataduck_users FROM somewhere CREDENTIALS 'aws_access_key_id=someaccesskeygoeshere;aws_secret_access_key=somesecretgoeshere' REGION 'us-west-1' CSV")).to eq("COPY zz_dataduck_users FROM somewhere CREDENTIALS 'aws_access_key_id=******;aws_secret_access_key=******' REGION 'us-west-1' CSV")
    end
  end
end

require 'field_methods'

describe FieldMethods do

  let (:split_string_success) {["test1", "test2", "test3"]}
  let (:split_string_uris_success) {["http://sws.geonames.org/5731780/", "http://sws.geonames.org/5785294/", "http://sws.geonames.org/5809218/"]}

  describe "field_split" do
    context "when given a string with ; as delimiter" do
      it "splits the string" do
        expect(FieldMethods.field_split("test1;test2; test3")).to eql(split_string_success)
      end
    end

    context "when given a string of URIs with ; as a delimiter" do
      it "splits the string" do
        expect(FieldMethods.field_split("http://sws.geonames.org/5731780/; http://sws.geonames.org/5785294/; http://sws.geonames.org/5809218/")).to eql(split_string_uris_success)
      end
    end

    context "when given a string with || as delimiter" do
      it "splits the string" do
        expect(FieldMethods.field_split("test1||test2||test3")).to eql(split_string_success)
      end
    end

    context "when given a string with more than 1 delimiter" do
      skip "splits the string" do
        expect(FieldMethods.field_split("test1||test2;test3")).to eql(split_string_success)
      end
    end

    context "when given a string with no delimiter" do
      let (:test_string) {"test1, test2"}

      it "returns the same string as an Array" do
        expect(FieldMethods.field_split(test_string)).to eql(Array(test_string))
      end
    end
  end

end

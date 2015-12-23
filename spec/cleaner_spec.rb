# encoding: utf-8

require 'spec_helper'

describe Bugsnag::Cleaner do
  subject { described_class.new(nil) }

  describe "#clean_object" do
    it "cleans up recursive hashes" do
      a = {:a => {}}
      a[:a][:b] = a
      expect(subject.clean_object(a)).to eq({:a => {:b => "[RECURSION]"}})
    end

    it "cleans up recursive arrays" do
      a = []
      a << a
      a << "hello"
      expect(subject.clean_object(a)).to eq(["[RECURSION]", "hello"])
    end

    it "allows multiple copies of the same string" do
      a = {:name => "bugsnag"}
      a[:second] = a[:name]
      expect(subject.clean_object(a)).to eq({:name => "bugsnag", :second => "bugsnag"})
    end

    it "allows multiple copies of the same object" do
      a = []
      b = ["hello"]
      a << b; a << b
      expect(subject.clean_object(a)).to eq([["hello"], ["hello"]])
    end

    it "cleans up UTF8 strings properly" do
      obj = "André"
      expect(subject.clean_object(obj)).to eq("André")
    end

    it "cleans up binary strings properly" do
      if RUBY_VERSION > "1.9"
        obj = "Andr\xc7\xff"
        if obj.respond_to? :force_encoding
          obj = obj.force_encoding('BINARY')
        end
        expect(subject.clean_object(obj)).to eq("Andr��")
      end
    end

    it "cleans up strings returned from #to_s properly" do
      if RUBY_VERSION > "1.9"
        str = "Andr\xc7\xff"
        if str.respond_to? :force_encoding
          str = str.force_encoding('BINARY')
        end
        obj = RuntimeError.new(str)
        expect(subject.clean_object(obj)).to eq("Andr��")
      end
    end

    it "filters by string inclusion" do
      expect(described_class.new(['f']).clean_object({ :foo => 'bar' })).to eq({ :foo => '[FILTERED]' })
      expect(described_class.new(['b']).clean_object({ :foo => 'bar' })).to eq({ :foo => 'bar' })
    end

    it "filters by regular expression" do
      expect(described_class.new([/fb?/]).clean_object({ :foo => 'bar' })).to eq({ :foo => '[FILTERED]' })
      expect(described_class.new([/fb+/]).clean_object({ :foo => 'bar' })).to eq({ :foo => 'bar' })
    end

    it "filters deeply nested keys" do
      params = {:foo => {:bar => "baz"}}
      expect(described_class.new([/^foo\.bar/]).clean_object(params)).to eq({:foo => {:bar => '[FILTERED]'}})
    end

    it "filters deeply nested request parameters" do
      params = {:request => {:params => {:foo => {:bar => "baz"}}}}
      expect(described_class.new([/^foo\.bar/]).clean_object(params)).to eq({:request => {:params => {:foo => {:bar => '[FILTERED]'}}}})
    end
  end

  describe "#clean_url" do
    let(:filters) { [] }
    subject { described_class.new(filters).clean_url(url) }

    context "with no filters configured" do
      let(:url) { "/dir/page?param1=value1&param2=value2" }
      it { should eq "/dir/page?param1=value1&param2=value2" }
    end

    context "with no get params" do
      let(:url) { "/dir/page" }
      it { should eq "/dir/page" }
    end

    context "with no matching parameters" do
      let(:filters) { ["param3"] }
      let(:url) { "/dir/page?param1=value1&param2=value2" }
      it { should eq "/dir/page?param1=value1&param2=value2" }
    end

    context "with a single matching parameter" do
      let(:filters) { ["param1"] }
      let(:url) { "/dir/page?param1=value1&param2=value2" }
      it { should eq "/dir/page?param1=[FILTERED]&param2=value2" }
    end

    context "with partially matching parameters" do
      let(:filters) { ["param"] }
      let(:url) { "/dir/page?param1=value1&param2=value2&bla=yes" }
      it { should eq "/dir/page?param1=[FILTERED]&param2=[FILTERED]&bla=yes" }
    end

    context "with multiple matching filters" do
      let(:filters) { ["param1", "param2"] }
      let(:url) { "/dir/page?param1=value1&param2=value2&param3=value3" }
      it { should eq "/dir/page?param1=[FILTERED]&param2=[FILTERED]&param3=value3" }
    end

    context "with both string and regexp filters" do
      let(:filters) { ["param1", /param2/] }
      let(:url) { "/dir/page?param1=value1&param2=value2&param3=value3" }
      it { should eq "/dir/page?param1=[FILTERED]&param2=[FILTERED]&param3=value3" }
    end

    context "with matching regexp filters" do
      let(:filters) { [/\Aaccess_token\z/] }
      let(:url) { "https://host.example/sessions?access_token=abc123" }
      it { should eq "https://host.example/sessions?access_token=[FILTERED]" }
    end

    context "with partially-matching regexp filters" do
      let(:filters) { [/token/] }
      let(:url) { "https://host.example/sessions?access_token=abc123" }
      it { should eq "https://host.example/sessions?access_token=[FILTERED]" }
    end
  end
end

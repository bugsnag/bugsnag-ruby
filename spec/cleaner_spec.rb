# encoding: utf-8

require 'spec_helper'

describe Bugsnag::Cleaner do
  subject { Bugsnag::Cleaner.new(Bugsnag::Configuration.new) }

  describe "#clean_object" do
    is_jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

    it "cleans up recursive hashes" do
      a = {:a => {}}
      a[:a][:b] = a
      expect(subject.clean_object(a)).to eq({:a => {:b => "[RECURSION]"}})
    end

    it "cleans up hashes when keys infinitely recurse in to_s" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      class RecursiveHashKey
        def to_s
          to_s
        end
      end

      key = RecursiveHashKey.new

      a = {}
      a[key] = 1

      expect(subject.clean_object(a)).to eq({ "[RECURSION]" => "[FILTERED]" })
    end

    it "cleans up hashes when a nested key infinitely recurse in to_s" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      class RecursiveHashKey
        def to_s
          to_s
        end
      end

      key = RecursiveHashKey.new

      a = {}
      a[:b] = {}
      a[:b][key] = 1

      expected = { :b => { "[RECURSION]" => "[FILTERED]" } }

      expect(subject.clean_object(a)).to eq(expected)
    end

    it "cleans up hashes when keys raise in to_s" do
      class RaisingHashKey
        def to_s
          raise "hey!"
        end
      end

      key = RaisingHashKey.new

      a = {}
      a[key] = 1

      expect(subject.clean_object(a)).to eq({ "[RAISED]" => "[FILTERED]" })
    end

    it "cleans up hashes when nested keys raise in to_s" do
      class RaisingHashKey
        def to_s
          raise "hey!"
        end
      end

      key = RaisingHashKey.new

      a = {}
      a[:b] = {}
      a[:b][key] = 1

      expected = { :b => { "[RAISED]" => "[FILTERED]" } }

      expect(subject.clean_object(a)).to eq(expected)
    end

    it "cleans up recursive arrays" do
      a = []
      a << a
      a << "hello"
      expect(subject.clean_object(a)).to eq(["[RECURSION]", "hello"])
    end

    it "doesn't remove nil from arrays" do
      a = ["b", nil, "c"]
      expect(subject.clean_object(a)).to eq(["b", nil, "c"])
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

    it "cleans custom objects" do
      class Macaron; end
      a = Macaron.new
      expect(subject.clean_object(a)).to eq('[OBJECT]')
    end

    it "cleans custom objects when they infinitely recurse" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      class RecursiveObject
        def to_s
          to_s
        end
      end

      object = RecursiveObject.new

      expect(subject.clean_object(object)).to eq("[RECURSION]")
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
      object = { events: { metaData: { foo: 'bar' } } }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = ['f']

      cleaner = Bugsnag::Cleaner.new(configuration)
      expect(cleaner.clean_object(object)).to eq({ events: { metaData: { foo: '[FILTERED]' } } })

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = ['b']

      cleaner = Bugsnag::Cleaner.new(configuration)
      expect(cleaner.clean_object(object)).to eq({ events: { metaData: { foo: 'bar' } } })
    end

    it "filters by regular expression" do
      object = { events: { metaData: { foo: 'bar' } } }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/fb?/]

      cleaner = Bugsnag::Cleaner.new(configuration)
      expect(cleaner.clean_object(object)).to eq({ events: { metaData: { foo: '[FILTERED]' } } })

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/fb+/]

      cleaner = Bugsnag::Cleaner.new(configuration)
      expect(cleaner.clean_object(object)).to eq({ events: { metaData: { foo: 'bar' } } })
    end

    it "filters deeply nested keys" do
      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/^foo\.bar/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      params = { events: { metaData: { foo: { bar: 'baz' } } } }
      expect(cleaner.clean_object(params)).to eq({ events: { metaData: { foo: { bar: '[FILTERED]' } } } })
    end

    it "filters deeply nested request parameters" do
      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/^foo\.bar/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      params = { events: { metaData: { request: { params: { foo: { bar: 'baz' } } } } } }
      expect(cleaner.clean_object(params)).to eq({ events: { metaData: { request: { params: { foo: { bar: '[FILTERED]' } } } } } })
    end

    it "doesn't filter by string inclusion when the scope is not in 'scopes_to_filter'" do
      object = { foo: 'bar' }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = ['f']

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(object)).to eq({ foo: 'bar' })

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = ['b']

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(object)).to eq({ foo: 'bar' })
    end

    it "doesn't filter by regular expression when the scope is not in 'scopes_to_filter'" do
      object = { foo: 'bar' }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/fb?/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(object)).to eq({ foo: 'bar' })

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/fb+/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(object)).to eq({ foo: 'bar' })
    end

    it "doesn't filter deeply nested keys when the scope is not in 'scopes_to_filter'" do
      params = { foo: { bar: 'baz' } }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/^foo\.bar/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(params)).to eq({ foo: { bar: 'baz' } })
    end

    it "doesn't filter deeply nested request parameters when the scope is not in 'scopes_to_filter'" do
      params = { request: { params: { foo: { bar: 'baz' } } } }

      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = [/^foo\.bar/]

      cleaner = Bugsnag::Cleaner.new(configuration)

      expect(cleaner.clean_object(params)).to eq({ request: { params: { foo: { bar: 'baz' } } } })
    end

    it "filters objects which can't be stringified" do
      class StringRaiser
        def to_s
          raise 'Oh no you do not!'
        end
      end
      expect(subject.clean_object({ :foo => StringRaiser.new })).to eq({ :foo => '[RAISED]' })
    end
  end

  describe "#clean_url" do
    let(:filters) { [] }

    subject do
      configuration = Bugsnag::Configuration.new
      configuration.meta_data_filters = filters
      described_class.new(configuration).clean_url(url)
    end

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

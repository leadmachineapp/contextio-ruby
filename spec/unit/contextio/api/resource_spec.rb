require 'spec_helper'
require 'contextio/api/resource'

describe ContextIO::API::Resource do
  describe "#validate_options" do
    context "with a string primary key" do
      subject do
        Class.new do
          include ContextIO::API::Resource

          primary_key 'string'
        end
      end

      it "matches a symbol" do
        expect { subject.new(double('api'), string: 'foo') }.to_not raise_error
      end

      it "matches a string" do
        expect { subject.new(double('api'), 'string' => 'foo') }.to_not raise_error
      end

      it "raises with missing keys" do
        expect { subject.new(double('api'), foo: 'bar') }.to raise_error
      end

      it "doesn't raise if resource_url is set" do
        expect { subject.new(double('api'), resource_url: 'some url') }.to_not raise_error
      end
    end

    context "with a symbol primary key"
      subject do
        Class.new do
          include ContextIO::API::Resource

          primary_key :symbol
        end
      end

      it "matches a string" do
        expect { subject.new(double('api'), 'symbol' => 'foo') }.to_not raise_error
      end

      it "matches a symbol" do
        expect { subject.new(double('api'),  symbol: 'bar') }.to_not raise_error
      end

      it "raises with missing keys" do
        expect { subject.new(double('api'), foo: 'bar') }.to raise_error
      end

      it "doesn't raise if resource_url is set" do
        expect { subject.new(double('api'), resource_url: 'some url') }.to_not raise_error
      end
  end

  describe ".lazy_attributes" do
    let(:helper_class) do
      Class.new do
        include ContextIO::API::Resource

        lazy_attributes :foo
      end
    end

    let(:api) do
      double('api', request: {'foo' => 'set from API'})
    end

    subject { helper_class.new(api, resource_url: 'resource_url') }

    it "defines a method for the attribute" do
      expect(subject).to respond_to(:foo)
    end

    context "when the attribute is set at creation" do
      subject do
        helper_class.new(api, resource_url: 'resource_url', foo: 'foo')
      end

      it "returns the value set" do
        expect(subject.foo).to eq('foo')
      end

      it "doesn't try to fetch from the API" do
        subject.should_not_receive(:fetch_attributes)

        subject.foo
      end
    end

    context "when the attributes is not set at creation" do
      it "tries to fetch from the API" do
        api.should_receive(:request).with(:get, 'resource_url').
          and_return({'foo' => 'set from API'})

        subject.foo
      end

      it "returns the value from the API" do
        expect(subject.foo).to eq('set from API')
      end
    end
  end

  describe "#fetch_attributes" do
    let(:helper_class) do
      Class.new do
        include ContextIO::API::Resource
      end
    end

    subject do
      helper_class.new(double('api'), resource_url: 'resource_url')
    end

    it "makes a request to the API" do
      subject.api.should_receive(:request).with(:get, 'resource_url').and_return({})

      subject.send(:fetch_attributes)
    end

    it "defines getter methods for new attributes returned" do
      subject.api.stub(:request).and_return(foo: 'bar')

      subject.send(:fetch_attributes)

      expect(subject.foo).to eq('bar')
    end

    it "doesn't override existing getter methods" do
      def subject.foo
        'hard coded value'
      end

      subject.api.stub(:request).and_return(foo: 'bar')

      subject.send(:fetch_attributes)

      expect(subject.foo).to eq('hard coded value')
    end

    it "stores the response hash" do
      subject.api.stub(:request).and_return(foo: 'bar')

      subject.send(:fetch_attributes)

      expect(subject.api_attributes).to eq(foo: 'bar')
    end
  end

  describe "#api_attributes" do
    let(:helper_class) do
      Class.new do
        include ContextIO::API::Resource
      end
    end

    let(:api) do
      double('api', request: { foo: 'bar', boolean: false })
    end

    subject do
      helper_class.new(api, resource_url: 'resource_url')
    end

    it "hits the API only on first call" do
      api.should_receive(:request).exactly(:once)

      subject.api_attributes
      subject.api_attributes
    end

    it "caches the api response hash" do
      expect(subject.api_attributes).to eq(foo: 'bar', boolean: false)
    end
  end

  describe "#resource_url" do
    let(:helper_class) do
      Class.new do
        include ContextIO::API::Resource

        primary_key :foo

        def build_resource_url
        end
      end
    end

    context "when one is set at creation" do
      subject do
        helper_class.new(double('api'), resource_url: 'resource_url')
      end

      it "returns the one passed in" do
        expect(subject.resource_url).to eq('resource_url')
      end
    end

    context "when one is not set at creation" do
      subject do
        helper_class.new(double('api'), foo: 'bar')
      end

      it "calls build_resource_url" do
        subject.should_receive(:build_resource_url)

        subject.resource_url
      end
    end
  end

  describe "#delete" do
    let(:helper_class) do
      Class.new do
        include ContextIO::API::Resource
      end
    end

    subject do
      helper_class.new(double('api', :request => {'success' => true}), resource_url: 'resource_url')
    end

    it "makes a request to the API" do
      subject.api.should_receive(:request).with(:delete, 'resource_url')

      subject.delete
    end

    it "returns the contents of the 'success' key" do
      expect(subject.delete).to eq(true)
    end
  end
end

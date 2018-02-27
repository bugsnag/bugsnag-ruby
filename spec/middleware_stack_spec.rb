require 'spec_helper'

class TestMiddleware
  def initialize(bugsnag)
    @bugsnag = bugsnag
  end

  def call(report)
    @bugsnag.call(report)
  end
end

module Bugsnag
  class MiddlewareStack
    attr_reader :middlewares
    attr_reader :disabled_middleware
  end
end

describe Bugsnag::MiddlewareStack do
  describe "defaults" do
    it "to empty middleware lists" do
      expect(subject.middlewares.size).to eq(0)
      expect(subject.disabled_middleware.size).to eq(0)
    end
  end

  describe "use" do
    it "allows middleware to be added to the stack" do
      middleware = TestMiddleware.new(nil)
      subject.use(middleware)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.last).to eq(middleware)
    end

    it "doesn't add middleware more than once" do
      middleware = TestMiddleware.new(nil)
      subject.use(middleware)
      expect(subject.middlewares.size).to eq(1)
      subject.use(middleware)
      expect(subject.middlewares.size).to eq(1)
    end
  end

  describe "disable" do
    it "adds middleware to a disabled list" do
      middleware = TestMiddleware.new(nil)
      subject.disable(middleware)
      expect(subject.disabled_middleware.size).to eq(1)
      expect(subject.disabled_middleware.last).to eq(middleware)
    end

    it "prevents middleware from being added" do
      middleware = TestMiddleware.new(nil)
      subject.disable(middleware)
      subject.use(middleware)
      expect(subject.middlewares.size).to eq(0)
    end

    it "removes already added middleware" do
      middleware = TestMiddleware.new(nil)
      subject.use(middleware)
      expect(subject.middlewares.size).to eq(1)
      subject.disable(middleware)
      expect(subject.middlewares.size).to eq(0)
    end
  end

  describe "insert_before" do
    it "inserts middleware before specified middleware" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      subject.use(middleware_one)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.first).to eq(middleware_one)
      subject.insert_before(middleware_one, middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.first).to eq(middleware_two)
    end

    it "appends middleware otherwise" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      subject.use(middleware_one)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.first).to eq(middleware_one)
      subject.insert_before(nil, middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.first).to eq(middleware_one)
    end

    it "accepts an array of middleware to insert before" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      middleware_three = TestMiddleware.new(nil)
      subject.use(middleware_one)
      subject.use(middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.first).to eq(middleware_one)
      subject.insert_before([middleware_one, middleware_two], middleware_three)
      expect(subject.middlewares.size).to eq(3)
      expect(subject.middlewares.first).to eq(middleware_three)
    end
  end

  describe "insert_after" do
    it "inserts middleware after specified middleware" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      subject.use(middleware_one)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.first).to eq(middleware_one)
      subject.insert_after(middleware_one, middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.last).to eq(middleware_two)
    end

    it "appends middleware otherwise" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      subject.use(middleware_one)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.first).to eq(middleware_one)
      subject.insert_after(nil, middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.first).to eq(middleware_one)
    end

    it "accepts an array of middleware to insert after" do
      middleware_one = TestMiddleware.new(nil)
      middleware_two = TestMiddleware.new(nil)
      middleware_three = TestMiddleware.new(nil)
      subject.use(middleware_one)
      subject.use(middleware_two)
      expect(subject.middlewares.size).to eq(2)
      expect(subject.middlewares.last).to eq(middleware_two)
      subject.insert_after([middleware_one, middleware_two], middleware_three)
      expect(subject.middlewares.size).to eq(3)
      expect(subject.middlewares.last).to eq(middleware_three)
    end
  end

  describe "method_missing" do
    it "calls send and proxies the method into the array" do
      middleware = TestMiddleware.new(nil)
      subject.method_missing(:<<, middleware)
      expect(subject.middlewares.size).to eq(1)
      expect(subject.middlewares.last).to eq(middleware)
    end
  end
end
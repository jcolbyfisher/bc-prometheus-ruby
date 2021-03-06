require 'spec_helper'

describe Bigcommerce::Prometheus::Servers::Thin::Server do
  let(:server) { described_class.new }

  before do
    Bigcommerce::Prometheus.reset
  end

  context 'when the thread pool size is not configured' do
    it 'falls back to the default configuration' do
      expect(server.threadpool_size).to eq ::Bigcommerce::Prometheus.server_thread_pool_size
      expect(server.threadpool_size).to eq 3
    end
  end

  context 'when the default thread pool size is configured' do
    let(:server_thread_pool_size) { 12 }

    before do
      Bigcommerce::Prometheus.configure do |c|
        c.server_thread_pool_size = server_thread_pool_size
      end
    end

    it 'allows you to set the thread pool size through the configuration block' do
      expect(server.threadpool_size).to eq server_thread_pool_size
    end
  end
end

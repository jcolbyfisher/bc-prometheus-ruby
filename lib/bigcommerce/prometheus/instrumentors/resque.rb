# frozen_string_literal: true

# Copyright (c) 2019-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Bigcommerce
  module Prometheus
    module Instrumentors
      ##
      # Instrumentors for resque process
      #
      class Resque
        include Bigcommerce::Prometheus::Loggable

        def initialize(app:)
          logger.debug "[bigcommerce-prometheus][#{@process_name}] initializing new Resque Instrumentor | #{@server_port}"
          @app = app
          @enabled = Bigcommerce::Prometheus.enabled
          @process_name = Bigcommerce::Prometheus.process_name
          @server_port = Bigcommerce::Prometheus.server_port
          @server_timeout = Bigcommerce::Prometheus.server_timeout
          @server_prefix = Bigcommerce::Prometheus.server_prefix
          @collectors = Bigcommerce::Prometheus.resque_collectors || []
          @type_collectors = Bigcommerce::Prometheus.resque_type_collectors || []
          logger.debug "[bigcommerce-prometheus][#{@process_name}] initialized new Resque Instrumentor | #{@server_port}"
        end

        ##
        # Start the web instrumentor
        #
        def start
          unless @enabled
            logger.debug "[bigcommerce-prometheus][#{@process_name}] Prometheus disabled, skipping resque start..."
            return
          end

          setup_middleware
        rescue StandardError => e
          logger.error "[bigcommerce-prometheus][#{@process_name}] Failed to start resque instrumentation - #{e.message} - #{e.backtrace[0..4].join("\n")}"
        end

        private

        def server
          @server ||= ::Bigcommerce::Prometheus::Server.new(
            port: @server_port,
            timeout: @server_timeout,
            prefix: @server_prefix
          )
        end

        def setup_server
          logger.debug "[bigcommerce-prometheus][#{@process_name}] starting new Resque Prometheus server | #{@server_port}"

          server.add_type_collector(PrometheusExporter::Server::ActiveRecordCollector.new)
          server.add_type_collector(Bigcommerce::Prometheus::TypeCollectors::Resque.new)
          @type_collectors.each do |tc|
            server.add_type_collector(tc)
          end
          server.start
          
          logger.debug "[bigcommerce-prometheus][#{@process_name}] started new Resque Prometheus server | #{@server_port}"
        end

        def setup_middleware
          logger.debug "[bigcommerce-prometheus][#{@process_name}] Setting up Resque Prometheus middleware"
          ::Resque.before_first_fork do
            setup_server
            ::Bigcommerce::Prometheus::Integrations::Resque.start(client: Bigcommerce::Prometheus.client)
            @collectors.each(&:start)
          end
          logger.debug "[bigcommerce-prometheus][#{@process_name}] Set up middleware for Resque Instrumentor | #{@server_port}"
        end
      end
    end
  end
end

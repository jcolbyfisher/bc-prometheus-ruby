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
      # Instrumentors for hutch process
      #
      class Hutch
        include Bigcommerce::Prometheus::Loggable

        def initialize(app:)
          @app = app
          @enabled = Bigcommerce::Prometheus.enabled
        end

        ##
        # Start the web instrumentor
        #
        def start
          unless @enabled
            logger.debug '[bigcommerce-prometheus] Prometheus disabled, skipping hutch start...'
            return
          end

          start_server
          setup_middleware
        rescue StandardError => e
          logger.error "[bigcommerce-prometheus] Failed to start hutch instrumentation - #{e.message} - #{e.backtrace[0..4].join("\n")}"
        end

        private

        def server
          @server ||= ::Bigcommerce::Prometheus::Server.new(
            port: @server_port,
            timeout: @server_timeout,
            prefix: @server_prefix
          )
        end

        def start_server
          logger.info "[bigcommerce-prometheus] Starting exporter on port #{@server_port} with timeout #{@server_timeout}"
          server.start
        end

        def setup_middleware
          logger.info '[bigcommerce-prometheus] Setting up hutch prometheus middleware'
          Hutch::Config.set(:tracer, PrometheusExporter::Instrumentation::Hutch)
          @app.middleware.unshift(PrometheusExporter::Middleware, client: Bigcommerce::Prometheus.client)
        end
      end
    end
  end
end

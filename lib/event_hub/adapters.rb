module EventHub::Adapters; end
require_relative 'adapters/bunny'
require_relative 'adapters/bunny/message'
require_relative 'adapters/aws'
require_relative 'adapters/aws/message'
require_relative 'adapters/test'
require_relative 'adapters/test/message'

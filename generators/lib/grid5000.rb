require 'grid5000/cluster'
require 'grid5000/node'

module Grid5000
  class Error < StandardError; end
  class MissingProperty < Grid5000::Error; end
end

require 'minitest/autorun'
require 'minitest/spec'

require 'statue'

Statue.backend = Statue::CaptureBackend.new

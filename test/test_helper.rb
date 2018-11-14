require 'minitest/autorun'
require 'minitest/spec'

require 'pry-rescue/minitest'

require 'statue'

Statue.backend = Statue::CaptureBackend.new

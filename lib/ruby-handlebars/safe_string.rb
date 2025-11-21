module Handlebars
  class SafeString < String
    def to_s
      self.class.new(self)
    end
  end
end

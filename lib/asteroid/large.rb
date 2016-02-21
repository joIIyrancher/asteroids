module Asteroid
  class Large < Asteroid::Base
    attr_reader :image, :shape, :body

    def points
      20
    end

    def chunks
      [Medium.new, Medium.new]
    end

    private

    def scale
      4
    end
  end
end

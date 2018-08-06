class SpatialGenerator
  attr_accessor :host
  def initialize(host)
    @host=host
  end

  def generate()
    # override
  end
end


class Gen_Apt_Straight < SpatialGenerator

end
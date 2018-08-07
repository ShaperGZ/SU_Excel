class BH_Generator < Arch::BlockUpdateBehaviour

  # generators["level1"]
  attr_accessor :generators
  # spaces["level1"]
  attr_accessor :spaces
  attr_accessor :invalidated

  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
    @generators = {"level1"=>{}, "level2"=>{},"level3"=>{}}
    @spaces = {"level1"=>[], "level2"=>[],"level3"=>[]}
    @invalidated =true
    #--------- finish basic initialization -----------------

    set_generator("level1", Generators::Gen_Apt_Straight.new(self))
    set_generator("level1", Generators::Gen_Cores.new(self))
    set_generator("level2", Generators::Decompose_FLBF.new(self))
    set_generator("level2", Generators::Decompose_F_STR.new(self))
  end

  def clear_spaces()
    (1..3).each{|i| @spaces["level#{i}"].each{|g| g.erase! if g.valid?}}
  end

  def onChangeEntity(e, invalidated)
    p "-->BH_Generator.onChangeEntity"
    return if not invalidated[2]
    # TODO: get size, and determine which generator to be used for invalidating
    invalidate(true)
  end

  def invalidate(forced=false)
    if @invalidated or forced
      clear_spaces()
      (1..3).each{|i| @generators["level#{i}"].values.each{|g| g.generate}}
    end
    @invalidated = false
  end

  def erase_space(level, space)
    index=@spaces[level].index(space)
    if index !=nil
      @spaces[level].delete_at(index)
      space.erase! if space.valid?
    end
  end

  def get_spaces(level,spatial_type=nil)
    result=[]
    if spatial_type == nil
      return @spaces[level].values.clone
    end
    @spaces[level].each{|s|
      if s.valid?
        t=s.get_attribute("BuildingComponent","type")
        if t == spatial_type
          result << s
        end
      end
    }
    return result
  end

  # def generate_geometry()
  #   (1..3).each{|i|
  #     @spaces["level#{i}"].each{|g|
  #       g.get_geometry()
  #     }
  #   }
  # end

  def set_generator(level, generator)
    @generators[level][generator.class]=generator
  end

  def write_gp()

  end

  def read_gp()

  end


end
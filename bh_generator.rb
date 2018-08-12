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
    @spaces_keys=["level1","level2","level3","def_holders","def_blocks"]
    @spaces = {}
    @spaces_keys.each{|k| @spaces[k] = []}
    @invalidated =true
    #--------- finish basic initialization -----------------

    set_generator("level1", Generators::Gen_Apt_Straight.new(self))
    set_generator("level1", Generators::Gen_Cores.new(self))
    # set_generator("level2", Generators::Decompose_FLBF.new(self))
    # set_generator("level2", Generators::Decompose_F_STR.new(self))
    set_generator("level2", Generators::Gen_Units.new(self))
    set_generator("level2", Generators::Gen_Area.new(self))
  end

  def gp()
    return @host.gp
  end

  def enable(type_name,flag,level="level2")
    p "bh_generator.enable"
    generators[level].each{|g|
      if g.class == type_name
        p "bh_generator.enble(..) found class #{type_name}"
        g.enable(flag)
      end
    }
  end

  def clear_spaces()
    @spaces_keys.each{|k| @spaces[k].each{|g| g.erase! if g.valid?}}
    @spaces_keys.each{|k| @spaces[k] = []}
  end

  def onChangeEntity(e, invalidated)
    p "-->BH_Generator.onChangeEntity"
    #return if not invalidated[2]
    # TODO: get size, and determine which generator to be used for invalidating
    invalidate(true)

    objs=[]
    objs+=@spaces["level1"]
    objs+=@spaces["level2"]
    objs+=@spaces["level3"]

    p "entities remain: #{objs.size}"
  end

  def invalidate(forced=true)
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
      return @spaces[level].clone
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
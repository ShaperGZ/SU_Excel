require 'csv'

$m2inch=39.3700787

class Variable
  attr_accessor :value
  attr_accessor :max
  attr_accessor :min
  attr_accessor :step

  def initialize(value,max=nil,min=nil,step=0.3)
    max=value*5 if max ==nil
    min = value*0.1 if min ==nil

    @value =value
    @max= max
    @min= min
    @step=step
  end

  def set(value, capped=true)
    if capped
      @value=cap(value)
    else
      @value=value
      @min=@value if @value<@min
      @max=@value if @value>@max
    end
  end

  def cap(val)
    if val<@min
      val= @min
    elsif val > @max
      val=@max
    end

    return val
  end

  def to_a()
    return [@value,@max,@min,@step]
  end

  def format()
    return "<#{@value}(#{@max},#{@min},#{@step})>"
  end

  def print()
    p format
  end
end

class Prototype
  attr_accessor :bd_width
  attr_accessor :bd_depth
  attr_accessor :bd_ftfh
  attr_accessor :bd_height
  attr_accessor :un_width
  attr_accessor :un_depth
  attr_accessor :fc_width
  @@str_param=["un_prototype"]

  def initialize()
    # basic attributes
    read_csv_params()

    #tool related attributes
    @point_1=nil
    @point_2=nil
    @point_3=nil
    @point_4=nil
    @xvect=Geom::Vector3d.new(@bd_width.value.m,0,0)
    @yvect=Geom::Vector3d.new(0,@bd_depth.value.m,0)
    @zvect=Geom::Vector3d.new(0,0,@bd_height.value.m)
  end

  def self.read_csv_params_to_gp(gp)
    str_params=@@str_param
    path=SUExcel.get_file_path('/Params.csv')
    params=CSV.read(path)
    for i in 1..params.size
      l=params[i]
      break if l ==nil
      name=l[1][0..-1]
      # p "reading #{name} val=#{l[2]}"
      if gp!=nil
        if l.size==6
          gp.set_attribute("BuildingBlock","p_"+name,[l[2].to_f,l[3].to_f,l[4].to_f,l[5].to_f])
        else

        end

        if str_params.include? name
          val=l[2]
        else
          val=l[2].to_f
        end
        gp.set_attribute("BuildingBlock",name,val)
      end # end if gp!=nil
    end # end for
  end

  def read_csv_params()
    path=SUExcel.get_file_path('/Params.csv')
    params=CSV.read(path)
    for i in 1..params.size
      l=params[i]
      break if l ==nil
      instance_variable_set('@'+l[1],Variable.new(l[2].to_f,l[3].to_f,l[4].to_f,l[5].to_f))
      #p "set @#{l[1]} to #{l[2]}"
    end
  end


  def confirm_creation
    gp=Sketchup.active_model.entities.add_group
    halfy=Geom::Vector3d.new(@yvect)
    halfy.length/=2
    org=@point_1 + halfy

    xvect=Geom::Vector3d.new(@xvect.length,0,0)
    yvect=Geom::Vector3d.new(0,@yvect.length,0)
    zvect=Geom::Vector3d.new(0,0,@zvect.length)

    pts=[]
    pts<< Geom::Point3d.new(0,-@yvect.length/2,0)
    pts<< Geom::Point3d.new(pts[0] + xvect)
    pts<< Geom::Point3d.new(pts[1] + yvect)
    pts<< Geom::Point3d.new(pts[0] + yvect)

    f=gp.entities.add_face(pts)
    f.reverse!
    f.pushpull(@zvect.length)

    t= Geom::Transformation.new(org,@xvect.normalize, @yvect.normalize)
    gp.transform! t

    @bd_width.set(@xvect.length / $m2inch)
    @bd_depth.set(@yvect.length / $m2inch)
    @bd_height.set(@zvect.length / $m2inch)

    Prototype.read_csv_params_to_gp(gp)
    gp.set_attribute("BuildingBlock","bd_wdith",@bd_width.value)
    gp.set_attribute("BuildingBlock","bd_depth",@bd_depth.value)
    gp.set_attribute("BuildingBlock","bd_height",@bd_height.value)

    # p "bd_width:#{@bd_width.format}"
    # p "bd_depth:#{@bd_depth.format}"
    # p "bd_height:#{@bd_height.format}"
    #
    # instance_variables.each{|v|
    #   name=v.to_s
    #   value = instance_variable_get(name)
    #   if value.class == Variable
    #     p "name=#{name} val=#{value}"
    #     #apt.instance_variable_set(name,value)
    #     gp.set_attribute("BuildingBlock","p_"+name[1..-1],[value.value, value.max,value.min,value.step])
    #     gp.set_attribute("BuildingBlock",name[1..-1],value.value)
    #
    #   end
    #
    # }

    apt=PrototypeAptBlock.create_or_invalidate(gp,zone="zone1",tower="t1",program="apartment",ftfh=@bd_ftfh.value)





  end

  # tool related methods
  # returns true if all 3 points are not set
  # returns false if all 3 points are set
  def set_point(pt)
    if @point_1 == nil
      @point_1=pt
    elsif @point_2 == nil
      @point_2 = pt
    elsif @point_3 == nil
      @point_3 = pt
    elsif @point_4 == nil
      @point_4 = pt
    end

    set_vects()
    true
  end

  def set_vects()
    @zvect=Geom::Vector3d.new(0,0,1)
    if @point_1 == nil or @point_2 == nil
      @xvect=Geom::Vector3d.new(1,0,0)
      @yvect=Geom::Vector3d.new(0,0,1).cross(@xvect.normalize)
    elsif @point_4 == nil
      @xvect=@point_2-@point_1
      @yvect=Geom::Vector3d.new(0,0,1).cross(@xvect.normalize)
    else
      @zvect.length=(@point_4-@point_1).length
    end

    #set x length
    if @xvect.length ==1
      @xvect.length=@bd_width.value.m
    else
      @bd_width.set(@xvect.length.to_m, true)
      @xvect.length=@bd_width.value.m
    end

    #set y length
    if @yvect.length ==1
      @yvect.length=@bd_depth.value.m
    else
      @bd_depth.set(@yvect.length.to_m, true)
      @yvect.length =@bd_depth.value.m
    end

    #set z length
    if @zvect.length ==1
      @zvect.length=@bd_height.value.m
    else
      @bd_height.set(@zvect.length.to_m, true)
      @zvect.length =@bd_height.value.m
    end


  end

  def picked_points()
    return [@point_1, @point_2, @point_3, @point_4]
  end

  # this is to be called in tool.draw(view)
  # override
  def draw(view,mouse_pos)

    pts_base=[]
    if @point_1 ==nil
      pts_base<<mouse_pos
    else
      pts_base<<@point_1
    end
    set_vects()

    pts_base<<pts_base[0] + @xvect
    pts_base<<pts_base[1] + @yvect
    pts_base<<pts_base[0] + @yvect
    pts_top=[]
    pts_base.each{|p| pts_top<< p + @zvect }

    pts_verts=[]
    for i in 0..pts_base.size-1
      pts_verts<<pts_base[i]
      pts_verts<<pts_top[i]
    end

    view.draw(GL_LINE_LOOP,pts_base)
    view.draw(GL_LINE_LOOP,pts_top)
    view.draw(GL_LINES,pts_verts)

  end
end
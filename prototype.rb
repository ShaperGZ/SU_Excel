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

  def set(value)
    @value=value
    @min=@value if @value<@min
    @max=@value if @value>@max
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

    p "bd_width:#{@bd_width.format}"
    p "bd_depth:#{@bd_depth.format}"
    p "bd_height:#{@bd_height.format}"

    instance_variables.each{|v|
      name=v.to_s
      value = instance_variable_get(name)
      if value.class == Variable
        p "name=#{name} val=#{value}"
        #apt.instance_variable_set(name,value)
        gp.set_attribute("BuildingBlock","p_"+name[1..-1],[value.value, value.max,value.min,value.step])
        gp.set_attribute("BuildingBlock",name[1..-1],value.value)

      end

    }


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
      @xvect=@point_2-@point_1
      @bd_width.value = @xvect.length / $m2inch
      @yvect=Geom::Vector3d.new(0,0,1).cross(@xvect.normalize)
      @yvect.length =@bd_depth.value * $m2inch
    elsif @point_3 == nil
      @point_3 = pt
      @yvect.length=(@point_3-@point_1).length
      @bd_depth.value = @yvect.length / $m2inch
    elsif @point_4 == nil
      @point_4 = pt
      @zvect.length=(@point_4-@point_1).length
      @bd_height = @zvect.length / $m2inch
      return false
    end
    true
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

    if @point_1 !=nil and @point_2 == nil
      mouse_pos.z=@point_1.z
      @xvect=mouse_pos-@point_1
      @yvect=Geom::Vector3d.new(0,0,1).cross(@xvect.normalize)
      @yvect.length=@bd_depth.value * $m2inch
    end

    if @point_2 !=nil and @point_3 == nil
      mouse_pos.z=@point_2.z
      v=mouse_pos-@point_1
      @yvect=Geom::Vector3d.new(0,0,1).cross(@xvect.normalize)
      @yvect.length=v.length
    end

    if @point_3 !=nil and @point_4 == nil

      v=mouse_pos-@point_1
      @zvect=Geom::Vector3d.new(0,0,1)
      @zvect.length=v.length
    end


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
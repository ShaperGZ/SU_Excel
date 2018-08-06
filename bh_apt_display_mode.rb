class BH_Apt_DisplayMode < Arch::BlockUpdateBehaviour
  attr_accessor :enabled
  def initialize(gp,host)
    super(gp,host)
    @enabled=false
    @generated_objects=nil
  end

  def show(flag=true)
    if not flag
      @enabled=flag
      @gp.hidden=false
      @generated_objects.hidden=true if @generated_objects!=nil and @generated_objects.valid?
      cuts=BuildingBlock.created_objects[@gp].get_updator_by_type(BH_CalArea).cuts
      cuts.hidden=false
      return
    elsif not @enabled and flag
      invalidate()
    end

    @enabled=flag
  end

  def onChangeEntity(e, invalidated)
    return if not enabled
    invalidate(invalidated)
  end

  def invalidate(invalidated=nil)
    @host.enableUpdate=false
    model= Sketchup.active_model
    model.start_operation('show_units')

    #show_units

    model.commit_operation
    @host.enableUpdate=true
  end

  def show_circulation()
    pts=ArchUtil.local_cut_face(@gp,0,false)

  end


  def _gen_unit_grids()
    xscale=@gp.transformation.xscale
    yscale=@gp.transformation.yscale
    zscale=@gp.transformation.zscale

    bd_width = host.attr("bd_width")
    bd_depth = host.attr("bd_depth")

    ftfhs = host.attr("bd_ftfhs")
    un_width = host.attr("un_width")
    count=(bd_width/un_width).floor

    units = Sketchup.active_model.entities.add_group
    gap=0.5.m

    half_corridor=1
    un_depth=(bd_depth/2)-half_corridor
    un_depth=un_depth.m - gap


    level=0
    ftfhs.each{|h|
      for i in 0..count-1
        pos=Geom::Point3d.new(((i*un_width.m)+gap)/xscale,(half_corridor+gap)/yscale,level/zscale)
        size=[
            (un_width.m-gap)/xscale,
            (un_depth)/yscale,
            (h.m-gap)/zscale
        ]
        #p pos
        _box(pos,size,units)

        pos=Geom::Point3d.new(((i*un_width.m)+gap)/xscale,-bd_depth.m/2,level/zscale)
        size=[
            (un_width.m-gap)/xscale,
            (un_depth)/yscale,
            (h.m-gap)/zscale
        ]
        #p pos
        _box(pos,size,units)
      end
      level+=h.m
    }
    units.transformation = @gp.transformation

    return units
  end

  def _box(pos,size,container)
    pts=[]
    vx=Geom::Vector3d.new(1,0,0)
    vy=Geom::Vector3d.new(0,1,0)
    vz=Geom::Vector3d.new(0,0,1)

    vx.length=size[0]
    vy.length=size[1]

    pts<<pos
    pts<<pos + vx
    pts<<pts[1] + vy
    pts<<pts[0] + vy

    f=container.entities.add_face(pts)
    f.reverse! if f.normal.z <0
    f.pushpull(size[2])
  end

  #currently a very slow version
  def show_units()
    @generated_objects.erase! if @generated_objects!=nil and @generated_objects.valid?
    gp=@gp
    host=@host
    yscale=gp.transformation.yscale
    # host=BuildingBlock.created_objects[gp]
    bd_width=host.attr("bd_width")
    bd_depth=host.attr("bd_depth")
    un_width=host.attr("un_width")

    counter=(bd_width/un_width).floor
    p "counter=#{counter}"

    xscale=gp.transformation.xscale
    cuts=host.get_updator_by_type(BH_CalArea).cuts




    #intersect room areas
    units=_gen_unit_grids()

    @generated_objects=units
    # room_flrs=room_intersector.intersect(floors)
    # p "room_flrs = #{room_flrs}"
    #
    #
    # cutter=Sketchup.active_model.entities.add_group()
    # dists=[]
    # for i in 0..counter
    #   dists<< (un_width.m / xscale)
    # end
    # cutter = ArchUtil.local_cut_face_array(gp,dists,1,true)
    # ArchUtil.intersect(cutter,room_flrs,room_flrs)
    #
    # cutter.erase!
    gp.hidden=true
    cuts.hidden=true
  end

end
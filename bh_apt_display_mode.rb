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
      return
    elsif not @enabled and flag
      invalidate()
    end

    @enabled=flag
  end

  def onChangeEntity(e, invalidated)
    return if not enabled
    invalidate
  end

  def invalidate()
    @host.enableUpdate=false
    show_units
    @host.enableUpdate=true
  end

  def show_units()
    gp=@gp
    host=@host
    # host=BuildingBlock.created_objects[gp]
    bd_width=host.attr("bd_width")
    un_width=host.attr("un_width")
    counter=(bd_width/un_width).floor
    p "counter=#{counter}"

    xscale=gp.transformation.xscale
    offset=un_width.m / xscale
    floors=host.get_updator_by_type(BH_CalArea).cuts


    cutter=Sketchup.active_model.entities.add_group()
    for i in 0..counter
      pts=ArchUtil.local_cut_face(gp,1,false)
      for j in 0..pts.size-1
        pts[j]+=Geom::Vector3d.new(i*offset,0,0)
      end
      f=cutter.entities.add_face(pts)
    end
    cutter.transformation=gp.transformation

    cutter.entities.intersect_with(
        true,
        cutter.transformation,
        floors,
        floors.transformation,
        true,
        floors
    )
    cutter.erase!
    gp.hidden=true
  end

end
class BH_Apt_FaceConstraint < Arch::BlockUpdateBehaviour
  #TODO:
  # export attributes:
  # ui_apt_cap_max
  # ui_apt_cap_min
  # ui_apt_void_max
  # ui_apt_void_min
  # 
  def initialize(gp,host)
    super(gp,host)

    @widths=[3,1.5,nil]
    @caps=[nil,[15,-15],nil]
    @voids=[nil,[10,-10],nil]
  end

  def onClose(e)
    #p 'constrain face.onClose'
    constraint_all
  end

  def onElementModified(entities, e)
    # return if e.class != Sketchup::Face or !e.valid?
    # dir=nil
    # # do not constrain top/down faces
    # for i in 0..1
    #   if e.normal[i]==1
    #     dir=i
    #     break
    #   end
    # end
    # return if dir==nil
    # t=@gp.transformation
    # scales=[t.xscale,t.yscale,t.zscale]
    # scale=1
    # #scale=scales[i]
    # ArchUtil.constrain_face_dir(e,dir,@widths[dir],scale,
    #                             @caps[dir],@voids[dir])
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2] and @host.enableUpdate
    p '-> BH_FaceConstrain.onChangeEntity'
    #p 'constrain face.onChangeEntity'
    constraint_all
  end


  def constraint_all()
    @enableUpdate=false
    bd_depth=@gp.get_attribute("BuildingBlock","bd_depth")
    p "bd_depth=#{bd_depth}"
    # apt_cap_convex=@gp.get_attribute("BuildingBlock","apt_cap_convex")[0]
    # apt_cap_concave=@gp.get_attribute("BuildingBlock","apt_cap_concave")[0]
    # cap_max=bd_depth+apt_cap_convex
    # void_max=bd_depth-apt_cap_concave
    # @caps=[nil,[cap_max,-cap_max],nil]
    # @voids=[nil,[void_max,-void_max],nil]

    ftfh=@gp.get_attribute("BuildingBlock","bd_ftfh")
    if ftfh.class ==Array
      ftfh=ftfh[0]
    end
    @widths[2]=ftfh
    ArchUtil.constraint_gp(@gp,@widths,@caps,@voids)
    @enableUpdate=true
  end



  def constraint_scale_y()
    @host.enableUpdate=false
    if @gp.transformation.yscale != 1
      scale=1/@gp.transformation.yscale
      scaling=Geom::Transformation.scaling([1,scale,1])
      @gp.transform! scaling
    end
    @host.enableUpdate=true
  end

  def constraint_all()
    constraint_scale_y
  end


end
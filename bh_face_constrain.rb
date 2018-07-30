
class BH_FaceConstrain < Arch::BlockUpdateBehaviour

  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
    @ent_mod_counter=0
  end

  def onClose(e)
    @host.set_ftfhs
    @host.enableUpdate = false
    constrain_all
    @host.enableUpdate = true
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    @host.set_ftfhs
    @host.enableUpdate = false
    constrain_all
    @host.enableUpdate = true
  end

  def onElementModified(entities, e)
    constrain_one_faceZ(e) if e.class == Sketchup::Face and e.normal.z.abs == 1 and @host.enableUpdate
  end

  def constrain_one_faceZ(f)
    return if f.vertices[0] == nil
    return if f.vertices[0].deleted?
    return if f.vertices[0].position.z<=0


    zscale=@gp.transformation.zscale
    vpos=f.vertices[0].position
    length=vpos.z * zscale

    #p "zscale=#{@gp.transformation.zscale} h=#{length}"
    ftfh,abs_h = @host.get_ftfh_from_z(vpos.z)
    ftfh=ftfh.m
    if abs_h == 0
      offset=ftfh-length
    else
      remain = length % abs_h
      half = ftfh / 2
      if remain>=half
        offset=ftfh-remain
      else
        offset=-remain
      end
    end

    offset *= f.normal.z
    p "constrain_one_faceZ z:#{length.to_m} ftfh:#{ftfh.to_m} abd_h:#{abs_h.to_m} offset:#{offset.to_m}"
    f.pushpull(offset / zscale )

  end

  def constrain_all()
    return if @gp.deleted?
    tops=[]
    #p 'constrain all'
    @gp.entities.each{|e| tops<<e if e.class==Sketchup::Face and e.normal.z.abs==1
    }
    #p "top.size=#{tops.size}"
    for i in 0..tops.size-1
      e=tops[i]
      constrain_one_faceZ(e) if e.valid?
    end
  end
end
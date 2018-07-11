
class BH_CalArea < Arch::BlockUpdateBehaviour

  @@hide_cuts = false
  def self.set_hide(bool)
    @@hide_cuts = bool
  end

  def initialize(gp,host)
    super(gp,host)
  end

  #override the following methods
  def onOpen(e)
    super(e)
  end
  def onClose(e)
    super(e)
    invalidate

  end
  def onChangeEntity(e)
    super(e)
    invalidate

  end
  def onEraseEntity(e)
    super(e)
  end

  def invalidate()
    return if @host==nil
    @host.enableUpdate = false
    model= Sketchup.active_model
    model.start_operation('invalidate')
    invalidate_operation
    model.commit_operation
    @host.enableUpdate = true
  end

  def invalidate_operation()
    entity=@gp
    p "invalidateing #{entity}"
    removeCuts()
    ftfh=entity.get_attribute("BuildingBlock","ftfh")
    floors = cutFloor(entity,ftfh)
    @cuts = intersectFloors(entity,floors)
    if @cuts == nil
      return
    end
    @cuts.locked =true
    @cuts.name=$genName
    ttArea=calAreas()
    entity.set_attribute("BuildingBlock","area",ttArea)

    if @@hide_cuts
      @cuts.hidden = true
    end

  end

  def cutFloor(subject ,ftfh, foffset=1)

    modelEnts=Sketchup.active_model.entities
    cutter=modelEnts.add_group
    cutEnts=cutter.entities
    cutTrans=cutter.transformation
    #p subject.class
    subjectBound=subject.bounds
    subjectH = (subjectBound.max.z - subjectBound.min.z)
    #p "(", subjectH
    subjectH =  subjectH / $m2inch
    #p subjectH, ")"

    flrCount = (subjectH / ftfh).floor

    #按逆时针顺序提取boundingbox底部的四个点
    basePts=[
        subjectBound.corner(0)+(subjectBound.corner(0)-subjectBound.corner(3)),
        subjectBound.corner(1)+(subjectBound.corner(1)-subjectBound.corner(2)),
        subjectBound.corner(3)+(subjectBound.corner(3)-subjectBound.corner(0)),
        subjectBound.corner(2)+(subjectBound.corner(2)-subjectBound.corner(1))
    ]

    for i in 0..flrCount
      if basePts[0].z<subjectBound.max.z and (basePts[0].z+(1* $m2inch))<subjectBound.max.z
        f=cutter.entities.add_face(basePts)
        #sketchup 会把在0高度的面自动向下，所以要反过来
        f.reverse! if basePts[0].z==0
        ext=f.pushpull(foffset* $m2inch)
        basePts.each{|p| p.z=p.z+(ftfh * $m2inch)}
      end
    end

    return cutter
  end

  def intersectFloors(subject,floors)
    modelEnts=Sketchup.active_model.entities
    dup=subject.copy
    cuts=floors.intersect(dup)
    if cuts==nil
      dup.erase!
      floors.erase!
    end
    return cuts
  end

  def calAreas()
    ttArea=0
    @cuts.entities.each{|e| ttArea += e.area if e.class == Sketchup::Face and e.normal.z==1 }
    ttArea = ttArea / $m2inchsq
    return ttArea
  end

  def removeCuts()
    return if @cuts == nil or @cuts.deleted?
    @cuts.locked=false
    @cuts.erase!
  end
end

class BH_CalArea < Arch::BlockUpdateBehaviour
  @@visible=true
  def self.show(visible)
    @@visible=visible
    return 0 if BuildingBlock.created_objects.size < 1
    BuildingBlock.created_objects.each{|ent,bb|
      bh=bb.get_updator_by_type(self)
      if bh!=nil
        cuts=bh.cuts
        cuts.hidden=visible if cuts !=nil
      end
    }
  end

  attr_accessor :cuts
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
  def onChangeEntity(e, invalidated)
    p '-> BH_CalArea.onChangeEntity'
    super(e, invalidated)
    invalidate
    # TODO:move cuts to new position if no scale
    # if invalidated[2]
    #   invalidate
    # else
    #   # move cuts to new group position
    #   @cuts
    # end
  end
  def onEraseEntity(e)
    removeCuts
  end

  def invalidate()
    return if @host==nil
    @host.enableUpdate = false
    #model= Sketchup.active_model
    #model.start_operation('invalidate')
    invalidate_operation
    #model.commit_operation
    @host.enableUpdate = true
  end

  def invalidate_operation()
    entity=@gp
    #p "invalidateing #{entity}"
    removeCuts()
    ftfh=entity.get_attribute("BuildingBlock","bd_ftfh")
    floors = cutFloor(entity,ftfh)
    @cuts = intersectFloors(entity,floors)
    if @cuts == nil
      return
    end

    #TODO: set floor to attibute, currently failed because holes
    #flrs=get_floor_data_string(@cuts)
    ##entity.set_attribute("BuildingBlock","geo_floors",flrs)

    @cuts.locked = true
    @cuts.name=$genName
    ttArea=calAreas()
    entity.set_attribute("BuildingBlock","bd_area",ttArea)
  end


  def get_floor_data_string(cuts)
    flrs=[]
    cuts.entities.each{|e|
      if e.class == Sketchup::Face and e.normal.z == -1
        verts=[]
        e.vertices.each{|v|
          verts<<v.position
        }
        verts.reverse!
        flrs<<verts
      end
    }
    return flrs
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
    return nil if subject.deleted?
    modelEnts=Sketchup.active_model.entities
    dup=subject.copy
    cuts=floors.intersect(dup)
    if cuts==nil
      dup.erase!
      floors.erase!
      return nil
    end


    del=[]
    cuts.entities.each{|e|
      if e.class == Sketchup::Edge
        pass=false
        e.faces.each{|f|
          if f.normal.z==-1
            pass=true
            break
          end
        }

        del<<e if not pass

      end
    }
    for i in 0..del.size-1
      del[i].erase! if del[i] !=nil and del[i].valid?
    end

    # faces=[]
    # cuts.entities.each{|e|
    #   if e.class==Sketchup::Face and e.normal.z == -1
    #     faces<<e
    #   end
    # }
    # flrs=Sketchup.active_model.entities.add_group(faces)
    # flrs.transformation=cuts.transformation
    #cuts.erase!

    flrs=cuts

    return flrs
  end

  def calAreas()
    ttArea=0
    @cuts.entities.each{|e| ttArea += e.area if e.class == Sketchup::Face and e.normal.z==-1 }
    ttArea = ttArea / $m2inchsq
    return ttArea
  end

  def removeCuts()
    return if @cuts == nil or @cuts.deleted?
    @cuts.locked=false
    @cuts.erase!
  end
end
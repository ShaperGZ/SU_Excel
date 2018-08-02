
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
    @regen_cuts=true
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
    @regen_cuts=invalidated[2]
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
    model= Sketchup.active_model
    model.start_operation('cut floors')

    invalidate_operation

    model.commit_operation
    @host.enableUpdate = true
  end

  def invalidate_operation()

    if @regen_cuts
      removeCuts()
      @cuts= slice(@gp)
      if @cuts == nil
        return
      end

      #TODO: set floor to attibute, currently failed because holes
      #flrs=get_floor_data_string(@cuts)
      ##entity.set_attribute("BuildingBlock","geo_floors",flrs)

      @cuts.locked = true
      @cuts.name=$genName
      get_std_flrs
      ttArea=calAreas()
      @gp.set_attribute("BuildingBlock","bd_area",ttArea)
    else
      @cuts.transformation=@gp.transformation
    end
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


  # this dosn't work for holes， but very fast!
  def slice(subject, foffset=1, match_material=true)
    modelEnts=Sketchup.active_model.entities
    cutter=modelEnts.add_group
    cutter.transformation=subject.transformation
    cutter.transform! Geom::Transformation.translation([0,0,1.m])
    zscale=subject.transformation.zscale
    subjectBound=subject.local_bounds

    # 按逆时针顺序提取boundingbox底部的四个点
    # 后面加的括号里的向量是为了拿大个plane
    basePts=[
        subjectBound.corner(0)+(subjectBound.corner(0)-subjectBound.corner(3)),
        subjectBound.corner(1)+(subjectBound.corner(1)-subjectBound.corner(2)),
        subjectBound.corner(3)+(subjectBound.corner(3)-subjectBound.corner(0)),
        subjectBound.corner(2)+(subjectBound.corner(2)-subjectBound.corner(1))
    ]


    ftfhs=@gp.get_attribute("BuildingBlock","bd_ftfhs")
    for i in 0..ftfhs.size-1
      zoffset=ftfhs[i].m / zscale
      f=cutter.entities.add_face(basePts)
      #sketchup 会把在0高度的面自动向下，所以要反过来
      f.reverse! if f.normal.z<0
      basePts.each{|p| p.z=p.z+zoffset}

    end

    # intersect cutter and the group
    tbr=[]

    cutter.entities.each{|e| tbr<<e if e.class ==Sketchup::Edge}
    cutter.entities.intersect_with(
                       true,
                       cutter.transformation,
                       cutter,
                       cutter.transformation,
                       true,
                       @gp
    )
    #cutter.copy
    # remove outter edges
    for i in 0..tbr.size-1
      tbr[i].erase! if tbr[i].valid?
    end

    ArchUtil.remove_coplanar_edges(cutter.entities)
    cutter.transform! Geom::Transformation.translation([0,0,-1.m])
    cutter.material = @gp.material if match_material

    return cutter
  end

  def get_std_flrs()
    return if @cuts==nil
    dict=Hash.new
    indices=[]
    @cuts.entities.each{|e|
      if e.class == Sketchup::Face
        index=e.vertices[0].position.z
        dict[index]=e
        indices<<index
      end
    }
    indices.sort!
    std_flrs=Hash.new
    for i in 0..indices.size-1
      face=dict[indices[i]]
      key=face.area.round
      if std_flrs.key?(key)
        std_flrs[key][0]+=1
      else
        primiter=[]
        face.vertices.each{|v|
          primiter<<v.position.x
          primiter<<v.position.y
        }
        content=[1,primiter]
        std_flrs[key]=content
      end
    end
    p "BuildingBlock.get_std_flrs = #{std_flrs.size}"
    @gp.set_attribute("BuildingBlock","geo_std_flr",std_flrs.to_a)
    @gp.set_attribute("BuildingBlock","bd_std_flr",std_flrs.size)
  end

  # this was used when intersecting two solids
  def cutFloor(subject ,ftfh, foffset=1)

    modelEnts=Sketchup.active_model.entities
    cutter=modelEnts.add_group
    cutter.transformation=@gp.transformation

    #p subject.class
    subjectBound=subject.local_bounds
    subjectH = subjectBound.max.z

    flrCount = (subjectH / ftfh.m).floor

    # 按逆时针顺序提取boundingbox底部的四个点
    # 后面加的括号里的向量是为了拿大个plane
    basePts=[
        subjectBound.corner(0)+(subjectBound.corner(0)-subjectBound.corner(3)),
        subjectBound.corner(1)+(subjectBound.corner(1)-subjectBound.corner(2)),
        subjectBound.corner(3)+(subjectBound.corner(3)-subjectBound.corner(0)),
        subjectBound.corner(2)+(subjectBound.corner(2)-subjectBound.corner(1))
    ]


    for i in 0..flrCount
      if basePts[0].z<subjectBound.max.z and (basePts[0].z+(1.m))<subjectBound.max.z
        f=cutter.entities.add_face(basePts)
        #sketchup 会把在0高度的面自动向下，所以要反过来

        f.reverse! if f.normal.z<0
        ext=f.pushpull(foffset.m)
        basePts.each{|p| p.z=p.z+ftfh.m}
      end
    end

    return cutter
  end

  # this was used when intersecting two solids
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
    scale_factor = @cuts.transformation.xscale * @cuts.transformation.yscale
    ttArea=0

    @cuts.entities.each{|e|
      if e.class == Sketchup::Face
        # 因为是平房，所以to_m 两次 -_-!...
        ttArea += e.area.to_m.to_m
      end
    }
    ttArea = ttArea * scale_factor
    return ttArea
  end

  def removeCuts()
    return if @cuts == nil or @cuts.deleted?
    @cuts.locked=false
    @cuts.erase!
  end
end
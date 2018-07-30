



class BuildingBlock < Arch::Block

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,zone="zone1",tower="t1",program="retail",ftfh=3)
    # 删除非法reference只在读取新档案时有用，但放在这里保证每次选择都检查并清除非法组
    self.remove_deleted()

    # 如果这个组已经创建过，不能再创建，因为已经有了监听器
    # 所以只更新其属性，然后invalidate
    # 否则就新创建一个 BuuildingBlock, 在构造器里会invalidate
    if @@created_objects.key?(g)
      block=@@created_objects[g]
      block.setAttr4(zone,tower,program,ftfh)

      block.invalidate
      return block
    else
      return if g.name==$genName
      b=BuildingBlock.new(g,zone,tower,program,ftfh)
      b.invalidate
      return b
    end
  end


  def self.remove_deleted()
    hs=@@created_objects
    hs.keys.each{|k|
      gp=hs[k].gp
      hs.delete(k) if gp==nil or !gp.valid?
    }
  end


  
  def initialize(gp,zone="zone1",tower="t1",program="retail",ftfh=3)
    #p "(0) PreCrt created_objects.size=#{BuildingBlock.created_objects.size}"
    super(gp)
    #p "(1) PostCrt created_objects.size=#{BuildingBlock.created_objects.size}"
    setAttr4(zone,tower,program,ftfh)
    add_updators()
    # 以前是每次构建就invalidate,现在构建后要手动调用invalidate
    # invalidate
  end

  def add_updators()
    # modeling aid
    @updators << BH_ClearNakedEdge.new(gp,self)
    @updators << BH_FaceConstrain.new(gp,self)

    # procedural generation
    @updators << BH_CalArea.new(gp,self)
    # 先不要parapet, parapet 应该在合并所有形体后再判定边
    #@updators << BH_Parapet.new(gp,self)

    # visualization
    @updators << BH_Visualize.new(gp,self)

    # calculation & data sync
    @updators << BH_Dimension.new(gp, self)
    @updators << BH_ExcelConduit.new(gp,self)

    # 先不要BaseArea, 更新太慢了，不做动态，让人按按钮生成
    #@updators << BH_BaseArea.new(gp,self)


  end

  def get_updator_by_type(type_name)
    @updators.each{|u|
      return u if u.class == type_name
    }
    return nil
  end

  def setAttr4(zone,tower,program,ftfh)
    dict= Hash.new
    dict["pln_zone"]=zone
    dict["pln_tower"]=tower
    dict["pln_program"]=program
    dict["bd_ftfh"]=ftfh
    setAttrByDict(dict)
    # the following methods computes the ftfh for every floor
    set_ftfhs
  end
  def setAttrByDict(dict)
    dict.each{|kvp|
      k=kvp[0]
      v=kvp[1]
      @gp.set_attribute("BuildingBlock",k,v)
    }
  end

  def invalidate()
    @updators.each{|e| e.onClose(@gp)}
  end

  def set_ftfhs()
    bd_ftfh=@gp.get_attribute("BuildingBlock","bd_ftfh")
    if bd_ftfh.class == Float
      bd_ftfh=[bd_ftfh]
    end
    ftfhs=[]

    # total height
    tth=@gp.local_bounds.max.z * @gp.transformation.zscale
    tth=tth.to_m
    #p "total h =#{tth}"
    current_H=0
    counter=0
    while current_H < tth
      if counter<bd_ftfh.size
        ftfh=bd_ftfh[counter]
      else
        ftfh = bd_ftfh[-1]
      end
      current_H += ftfh
      ftfhs<<ftfh
      counter+=1
    end
    @gp.set_attribute("BuildingBlock","bd_floors",counter)
    @gp.set_attribute("BuildingBlock","bd_ftfhs",ftfhs)
    return ftfhs
  end

  # determins ftfh from local z value
  def get_ftfh_from_z(zval)
    ftfhs=@gp.get_attribute("BuildingBlock", "bd_ftfhs")
    unscaled_z=zval * @gp.transformation.zscale
    tt=0
    abs_h=0
    ftfh=ftfhs[0]
    for i in 0..ftfhs.size-1
      tt+=ftfhs[i].m
      if tt > unscaled_z
        ftfh=ftfhs[i]
        break
      end
      abs_h=tt
    end
    return ftfh,abs_h
  end


end



class BuildingBlock < Arch::Block

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,zone="zone1",tower="t1",program="retail",ftfh=3)
    # 删除非法reference只在读取新档案时有用，但放在这里保证每次选择都检查并清除非法组
    self.remove_deleted()

    # 如果这个组已经创建过，不能再创建，因为已经有了监听器
    # 所以只更新其属性，然后invalidate
    # 否则就新创建一个 BuuildingBlock, 在构造器里会invalidate
    if @@created_objects.key?(g.guid)
      block=@@created_objects[g.guid].setAttr(zone,tower,program,ftfh)
      block.invalidate
      return block
    else
      return BuildingBlock.new(g,zone,tower,program,ftfh)
    end
  end


  def self.remove_deleted()
    hs=@@created_objects
    hs.keys.each{|k|
      gp=hs[k].gp
      hs.delete(k) if gp==nil or gp.deleted?
    }
  end

  def initialize(gp,zone="zone1",tower="t1",program="retail",ftfh=3)
    super(gp)
    setAttr4(zone,tower,program,ftfh)
    @updators < BH_FaceConstrain.new(gp)
    #@updators < BH_CalArea.new(gp)

    invalidate
  end

  def setAttr4(zone,tower,program,ftfh)
    dict= Hash.new
    dict["zone"]=zone
    dict["tower"]=tower
    dict["program"]=program
    dict["ftfh"]=ftfh
    setAttrByDict(dict)
  end
  def setAttrByDict(dict)
    dict.each{|kvp|
      k=kvp[0]
      v=kvp[1]
      set_attribute("BuildingBlock",k,v)
    }
  end

  def invalidate()
    @updators.each{|e| e.onClose(@gp)}
  end

end
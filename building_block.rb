
class BuildingBlock < Arch::Block

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,zone=nil,tower=nil,program=nil,ftfh=nil)
    # 删除非法reference只在读取新档案时有用，但放在这里保证每次选择都检查并清除非法组
    self.remove_deleted()

    # 如果这个组已经创建过，不能再创建，因为已经有了监听器
    # 所以只更新其属性，然后invalidate
    # 否则就新创建一个 BuuildingBlock, 在构造器里会invalidate

    if !g.deleted? and @@created_objects.key?(g.guid)
      block=@@created_objects[g.guid]
      if program==nil and ftfh==nil
        zone=g.get_attribute("BuildingBlock","zone")
        tower=g.get_attribute("BuildingBlock","tower")
        program=g.get_attribute("BuildingBlock","program")
        ftfh=g.get_attribute("BuildingBlock","ftfh")
      end

      block.setAttr4(zone,tower,program,ftfh)
      block.invalidate
      return block
    else
      zone="zone1" if zone==nil
      tower="t1" if tower==nil
      program="retail" if program==nil
      ftfh=3 if ftfh==nil
      return BuildingBlock.new(g,zone,tower,program,ftfh)
    end
  end

  def self.remove_deleted()
    hs=@@created_objects
    count=0
    hs.keys.each{|k|
      gp=hs[k].gp
      if gp==nil or gp.deleted?
        hs.delete(k)
        count+=1
      end
    }
    p "#{count} objects are deleted from BuildingBlock.created_objects"
  end

  attr_accessor :updators
  def initialize(gp,zone="zone1",tower="t1",program="retail",ftfh=3)
    super(gp)
    setAttr4(zone,tower,program,ftfh)
    @updators << BH_FaceConstrain.new(gp,self)
    @updators << BH_CalArea.new(gp,self)
    @updators << BH_Visualize.new(gp,self)

    invalidate
  end

  def onClose(e)
    super(e)
    SUExcel.data_manager.onChangeEntity(e) if SUExcel.data_manager != nil
  end

  def onChangeEntity(e)
    super(e)
    SUExcel.data_manager.onChangeEntity(e) if SUExcel.data_manager != nil
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
      @gp.set_attribute("BuildingBlock",k,v)
      p "setting #{k} to #{v}"
    }
  end

  def invalidate()
    @updators.each{|e| e.onClose(@gp)}
    SUExcel.data_manager.onChangeEntity(@gp) if SUExcel.data_manager != nil
  end

end
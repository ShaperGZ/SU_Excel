


class PrototypeAptBlock < BuildingBlock

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,zone="zone1",tower="t1",program="retail",ftfh=3)
    self.remove_deleted()
    if @@created_objects.key?(g.guid)
      block=@@created_objects[g.guid]
      block.setAttr4(zone,tower,program,ftfh)
      block.invalidate
      return block
    else
      b=PrototypeAptBlock.new(g,zone,tower,program,ftfh)
      b.invalidate
      return b
    end
  end

  def initialize(g,zone,tower,program,ftfh)
    super(g,zone,tower,program,ftfh)
  end

  def add_updators()
    #@updators << BH_FaceConstrain.new(gp,self)
    @updators << BH_Apt_FaceConstraint.new(gp,self)
    @updators << BH_CalArea.new(gp,self)
    #@updators << BH_Parapet.new(gp,self)
  end

  def updators
    @updators
  end

end
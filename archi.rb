module Arch
  class EntsObs < Sketchup:: EntitiesObserver
    def initialize(host)
      @host=host
    end
    def onElementAdded(entities, entity)
      @host.onElementAdded(entities,entity) if @host.enableUpdate
    end
    def onElementModified(entities, entity)
      @host.onElementModified(entities, entity) if @host.enableUpdate
    end
  end

  class InstObs < Sketchup::InstanceObserver
    def initialize(host)
      @host=host
    end
    def onOpen(instance)
      @host.onOpen(instance) if @host.enableUpdate
    end
    def onClose(instance)
      @host.onClose(instance) if @host.enableUpdate
    end
  end

  class EntObs < Sketchup::EntityObserver
    def initialize(host)
      @host=host
    end
    def onEraseEntity(entity)
      @host.onEraseEntity(entity) if @host.enableUpdate
    end
    def onChangeEntity(entity)
      @host.onChangeEntity(entity) if @host.enableUpdate
    end
  end

  class BlockUpdateBehaviour
    attr_accessor :gp
    attr_accessor :host
    def initialize(gp,host=nil)
      @gp=gp
      @host=host
      @enableUpdate = true
    end

    def onOpen(e)
    end

    def onClose(e)
    end

    def onChangeEntity(e)
    end

    def onEraseEntity(e)
    end

    def onElementAdded(entities, e)
    end

    def onElementModified(entities, e)
    end
  end

  class Block < BlockUpdateBehaviour
    @@created_objects=Hash.new
    def self.created_objects
      @@created_objects
    end
    def self.create_or_get(g)
      if @@created_objects.key?(g)
        return @@created_objects[g]
      else
        return Block.new(g)
      end
    end

    def initialize (gp)
      super(gp)
      @enableUpdate = true
      @entObs=[]
      @entsObs=[]
      @updators=[]
      add_entsObserver(EntsObs.new(self))
      add_entObserver(EntObs.new(self))
      add_entObserver(InstObs.new(self))
      @@created_objects[gp]=self
    end
    def add_entObserver(observer)
      obs=@gp.add_observer(observer)
      @entObs<<observer
    end
    def add_entsObserver(observer)
      obs=@gp.entities.add_observer(observer)
      @entsObs<<observer
    end
    def enableUpdate()
      @enableUpdate
    end
    def enableUpdate=(val)
      @enableUpdate=val
    end

    # override the following methods
    def onOpen(e)
      @updators.each{|u| u.onOpen(e)} if @enableUpdate and @gp.valid?
    end
    def onClose(e)
      @updators.each{|u| u.onClose(e)} if @enableUpdate and @gp.valid?
    end

    def onChangeEntity(e)
      # 当删除物件的时候这个e会变成另一个地址，所以检查e组是否还存在要靠@gp.valid?
      if @enableUpdate and @gp.valid?
        count=0
        @updators.each{|u|
          p "executed u.gp:#{u.gp} u.valid=#{u.gp.valid?}"
          u.onChangeEntity(e)
        }
      else
        p "onChangeEntity group = #{e} , e.deleted=#{e.deleted?}, e.valid=#{e.valid?}"
      end
    end

    def onEraseEntity(e)
      # 删除时输入的e不等于@gp, 要用@gp来删除
      # p "onErase : e=#{e} @gp=#{@gp}"
      # 结果："onErase : e=#<Sketchup::Group:0x148d8548> @gp=#<Deleted Entity:0xee74bd0>"
      @updators.each{|u| u.onEraseEntity(@gp)} if @enableUpdate
      if @enableUpdate
        @@created_objects.delete(@gp)
      end
    end

    def onElementAdded(entities, e)
      @updators.each{|u| u.onElementAdded(entities, e)} if @enableUpdate and !e.deleted?
    end
    def onElementModified(entities, e)
      @updators.each{|u| u.onElementModified(entities, e)} if @enableUpdate and !e.deleted?
    end
  end
end
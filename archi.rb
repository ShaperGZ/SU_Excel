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
    attr_accessor :updators

    def self.created_objects
      @@created_objects
    end
    def self.create_or_get(g)
      if @@created_objects.key?(g.guid)
        return @@created_objects[g.guid]
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
      @@created_objects[gp.guid]=self
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

    #override the following methods
    def onOpen(e)
      @updators.each{|u| u.onOpen(e)} if @enableUpdate
    end
    def onClose(e)
      @updators.each{|u| u.onClose(e)} if @enableUpdate
    end
    def onChangeEntity(e)
      @updators.each{|u| u.onChangeEntity(e)} if @enableUpdate
    end
    def onEraseEntity(e)
      @updators.each{|u| u.onEraseEntity(e)} if @enableUpdate
      @@created_objects.delete(e.guid) if @enableUpdate
    end
    def onElementAdded(entities, e)
      @updators.each{|u| u.onElementAdded(entities, e)} if @enableUpdate
    end
    def onElementModified(entities, e)
      @updators.each{|u| u.onElementModified(entities, e)} if @enableUpdate
    end
  end
end
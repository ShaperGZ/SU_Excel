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

  class Block
    def initialize(gp)
      @enableUpdate = true
      @gp=gp
      @entObs=[]
      @entsObs=[]
      add_entsObserver(EntsObs.new(self))
      add_entObserver(EntObs.new(self))
      add_entObserver(InstObs.new(self))
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

    #override the following methods
    def onOpen(e)

    end
    def onClose(e)

    end
    def onChangeEntity(e)

    end
    def onEraseEntity(e)

    end
    def onElementAdded(entities, e)
      #p "added #{e}"
    end
    def onElementModified(entities, e)

    end
  end
end
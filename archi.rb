module Arch
  class EntsObs < Sketchup:: EntitiesObserver
    def initialize(host)
      @host=host
    end
    def onElementAdded(entities, entity)
      # model= Sketchup.active_model
      # model.start_operation('onElementAdded')
      @host.onElementAdded(entities,entity) if @host.enableUpdate
      # model.commit_operation
    end
    def onElementModified(entities, entity)
      # model= Sketchup.active_model
      # model.start_operation('onElementModified')
      @host.onElementModified(entities, entity) if @host.enableUpdate
      #model.commit_operation
    end
  end

  class InstObs < Sketchup::InstanceObserver
    def initialize(host)
      @host=host
    end
    def onOpen(instance)
      # model= Sketchup.active_model
      # model.start_operation('onOpen')
      @host.onOpen(instance) if @host.enableUpdate
      # model.commit_operation
    end
    def onClose(instance)
      # model= Sketchup.active_model
      # model.start_operation('onClose')
      @host.onClose(instance) if @host.enableUpdate
      # model.commit_operation

    end
  end

  class EntObs < Sketchup::EntityObserver

    def initialize(host)
      @host=host
      @last_transformation=@host.gp.transformation.clone
    end
    def onEraseEntity(entity)
      # model= Sketchup.active_model
      # model.start_operation('onErase')
      @host.onEraseEntity(entity) if @host.enableUpdate
      # model.commit_operation
    end
    def onChangeEntity(entity)
      return if not @host.gp.valid?
      invalidated=ArchUtil.invalidated_transformation?(@last_transformation, @host.gp.transformation)
      # model= Sketchup.active_model
      # model.start_operation('invalidate')
      sign="---"
      for i in 0..2
        sign[i]= '+' if invalidated[i]
      end
      p "#{sign} [ EntObs.onChangeEntity e:#{entity} ] host.gp:#{@host.gp}"
      @host.onChangeEntity(entity,invalidated) if @host.enableUpdate
      @last_transformation = @host.gp.transformation.clone
      # model.commit_operation

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

    def onChangeEntity(e, invalidated)
    end

    def onEraseEntity(e)
    end

    def onElementAdded(entities, e)
    end

    def onElementModified(entities, e)
    end

    def invalidate()

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
      p "set @enaleUpdate to: #{@enableUpdate}"
    end

    # override the following methods
    def onOpen(e)
      @updators.each{|u| u.onOpen(e)} if enableUpdate and @gp.valid?
    end
    def onClose(e)
      @updators.each{|u| u.onClose(e)} if enableUpdate and @gp.valid?
    end

    # invalidated 是一个长度为三的bool array, 指明那种变化已过期
    # invalidated: [pos,rot,scale]
    def onChangeEntity(e,invalidated)
      # 当删除物件的时候这个e会变成另一个地址，所以检查e组是否还存在要靠@gp.valid?
      if enableUpdate and @gp.valid?
        @updators.each{|u|
          #p "executed u.gp:#{u.gp} u.valid=#{u.gp.valid?}"
          u.onChangeEntity(@gp,invalidated)
        }
      end
    end

    def onEraseEntity(e)
      # 删除时输入的e不等于@gp, 要用@gp来删除
      if enableUpdate
        @updators.each{|u| u.onEraseEntity(@gp)}
        @@created_objects.delete(@gp)
      end
    end

    def onElementAdded(entities, e)
      @updators.each{|u| u.onElementAdded(entities, e)} if enableUpdate and !e.deleted?
    end
    def onElementModified(entities, e)
      #p "enable update=#{enableUpdate}"
      @updators.each{|u| u.onElementModified(entities, e)} if enableUpdate and !e.deleted?
    end
  end
end
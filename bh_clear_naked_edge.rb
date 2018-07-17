class BH_ClearNakedEdge < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
  end

  def onClose(e)
    super(e)
    invalidate
  end

  def invalidate()
    naked_edges=[]
    @gp.entities.each{|e|
      if e.class == Sketchup::Edge and e.valid?
        naked_edges<<e if e.faces.size == 0
      end
    }

    for i in 0..naked_edges.size-1
      e=naked_edges[i]
      e.erase!
    end
  end
end
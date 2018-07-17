
class BH_Parapet < Arch::BlockUpdateBehaviour
  @@visible=true
  def self.show(visible)
    @@visible=visible
    return 0 if BuildingBlock.created_objects.size < 1
    BuildingBlock.created_objects.each{|ent,bb|
      bh=bb.get_updator_by_type(self)
      if bh!=nil
        parapets=bh.parapet_container
        parapets.hidden=visible if parapets !=nil
      end
    }
  end

  attr_accessor :parapet_container
  attr_accessor :parapets
  def initialize(gp,host)
    super(gp,host)
    @parapet_container = nil
    @parapets=Hash.new
  end

  def onElementModified(entities, e)
    #invalidate()
  end

  def onOpen(e)
    remove_all()
  end

  def onClose(e)
    invalidate()
  end

  def onChangeEntity(e, invalidated)
    p '-> BH_FaceConstrain.onChangeEntity'
    invalidate()
  end

  def onEraseEntity(e)
    remove_all()
  end


  def invalidate()
    @host.enableUpdate = false
    remove_all()
    faces=[]
    @gp.entities.each{|e| faces<<e if e.class == Sketchup::Face and e.normal.z==1}
    faces.each{|f|
      fs=_make_parapet(f)
      @parapets[f]=fs
    }
    @host.enableUpdate = true
  end

  def remove_all()
    @parapet_container.erase! if @parapet_container != nil and !@parapet_container.deleted?
    #@parapet_container = @gp.entities.add_group()
    return if !@gp.valid?
    @parapet_container = Sketchup.active_model.entities.add_group()
    @parapet_container.transform! @gp.transformation
    @parapet_container.name =$genName
    @parapets=Hash.new
  end

  def _find_edges(face)
    valid_edges=[]
    sorted_vert_pairs=[]
    edges=face.edges

    edges.each{|e|
      v1,v2=_sort_direction(e,face)
      ve=v2.position.vector_to(v1.position).normalize
      ne=ve.cross(Geom::Vector3d.new(0,0,1))
      e.faces.each{|f|
        if f!= face and f.normal.z.abs !=1
          if f.normal != ne
            valid_edges << e
            sorted_vert_pairs << [v1,v2]
            break
          end
        end
      }
    }
    return valid_edges,sorted_vert_pairs
  end

  def _make_parapet(face)
    ps=[]
    edges,pairs=_find_edges(face)
    pairs.each{|prs|
      f=_extrude_edge(prs,@parapet_container.entities,1.1,)
      ps << f if f != nil and f.class == Sketchup::Face
    }
    return ps
  end

  def _extrude_edge(vert_pair,ents,height=1.1)
    zscale=@gp.transformation.to_a[10]
    height *= $m2inch / zscale
    v1=vert_pair[0].position
    v2=vert_pair[1].position
    v3=v2+Geom::Vector3d.new(0,0,height)
    v4=v1+Geom::Vector3d.new(0,0,height)

    ents=Sketchup.active_model.entities if ents == nil
    f = ents.add_face([v1,v2,v3,v4])
    return f
  end

  def _sort_direction(edge,face)
    v1=edge.vertices[0]
    v2=edge.vertices[1]
    i1=face.vertices.index(v1)
    i2=face.vertices.index(v2)
    diff = i2 - i1
    if diff == 1 or diff < -2
      return [v1,v2]
    else
      return [v2,v1]
    end
  end

end

class BH_FaceConstrain < Arch::BlockUpdateBehaviour

  def initialize(gp)
    super(gp)
  end

  def onClose(e)
    constrain_all
  end

  def onChangeEntity(e)
    constrain_all
  end

  def onElementAdded(entities, e)
    constrain_one_faceZ(e) if e.class == Sketchup::Face and e.normal.z.abs == 1
  end

  def onElementModified(entities, e)
    constrain_one_faceZ(e) if e.class == Sketchup::Face and e.normal.z.abs == 1
  end

  def constrain_one_faceZ(f)

    base_z=@gp.bounds.min.z
    return if f.vertices[0].position.z<=0
    #return if f.normal.z == -1 and f.vertices[0].position.z <= base_z
    zscale=@gp.transformation.to_a[10]
    step=@gp.get_attribute("BuildingBlock","ftfh")
    step /= zscale
    return if step==nil
    step*=$m2inch
    vpos=f.vertices[0].position

    #length=vpos.z - base_z
    #this length times group scale factor
    #length*=@gp.transformation.to_a[10]

    length=vpos.z
    remain = length % step

    half = step / 2
    if remain>=half
      offset=step-remain
    else
      offset=-remain
    end

    offset *= f.normal.z
    #offset= step - offset if f.normal.z == -1

    p "face.z=#{vpos.z / $m2inch},length=#{length / $m2inch}, remain=#{remain / $m2inch}, offset=#{offset / $m2inch}"
    f.pushpull(offset)
  end

  def constrain_all()

    tops=[]
    p 'constrain all'
    @gp.entities.each{|e| tops<<e if e.class==Sketchup::Face and e.normal.z.abs==1
    }
    tops.each {|e|
      #p e
      constrain_one_faceZ(e) }
  end
end
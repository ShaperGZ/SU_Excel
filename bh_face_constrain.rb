
class BH_FaceConstrain < Arch::BlockUpdateBehaviour

  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
  end

  def onClose(e)
    #p 'constrain face.onClose'
    constrain_all
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    p '-> BH_FaceConstrain.onChangeEntity'
    #p 'constrain face.onChangeEntity'
    constrain_all
  end

  def onElementAdded(entities, e)
    #p 'constrain face.onElementAdded'
    constrain_one_faceZ(e) if e.class == Sketchup::Face and e.normal.z.abs == 1
  end

  def onElementModified(entities, e)
    #p 'constrain face.onElementModified'
    constrain_one_faceZ(e) if e.class == Sketchup::Face and e.normal.z.abs == 1
  end

  def constrain_one_faceZ(f,local=true)
    return if f.vertices[0] == nil
    return if f.vertices[0].deleted?
    return if f.vertices[0].position.z<=0
    zscale=@gp.transformation.zscale


    #p "zscale=#{zscale}"

    step=@gp.get_attribute("BuildingBlock","bd_ftfh").to_f
    #p "step = #{step}"
    step /= zscale
    return if step==nil
    step*=$m2inch
    vpos=f.vertices[0].position

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

    #p "face.z=#{vpos.z / $m2inch},length=#{length / $m2inch}, remain=#{remain / $m2inch}, offset=#{offset / $m2inch}"
    f.pushpull(offset)
  end

  def constrain_all()
    return if @gp.deleted?
    tops=[]
    #p 'constrain all'
    @gp.entities.each{|e| tops<<e if e.class==Sketchup::Face and e.normal.z.abs==1
    }
    #p "top.size=#{tops.size}"
    tops.each {|e|
      constrain_one_faceZ(e,false) }
  end
end
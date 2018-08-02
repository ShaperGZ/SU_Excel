load 'D:\sketchupRuby\load\test.rb'
class BH_Apt_FaceConstraint < Arch::BlockUpdateBehaviour
  #TODO:
  # export attributes:
  # ui_apt_cap_max
  # ui_apt_cap_min
  # ui_apt_void_max
  # ui_apt_void_min
  # 
  def initialize(gp,host)
    super(gp,host)

    @widths=[3,1.5,nil]
    @caps=[nil,[15,-15],nil]
    @voids=[nil,[10,-10],nil]
    @external_transformation=@gp.transformation
  end

  def onClose(e)
    Testing.onClose(e,@gp)

  end

  def onElementModified(entities, e)
    Testing.onElementModified(entities, e, @gp,@external_transformation,@host)

  end

  def onChangeEntity(e, invalidated)
    @external_transformation=@gp.transformation
    Testing.onChangeEntity(e, invalidated,@gp,@external_transformation,@host)

  end

end
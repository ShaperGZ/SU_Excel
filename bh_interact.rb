class BH_Interact < Arch::BlockUpdateBehaviour


  def BH_Interact.set_bd_size(gp,size)
    # resize takes too much time
    # check if the sizes area the same before resize
    if not Op_Dimension.is_equal_size(gp,size)
      Op_Dimension.set_bd_size(gp,size)
      return true
    end
    return false
  end

  def set_gp_attr(key,value)
    @gp.set_attribute("BuildingBlock",key,value)

    # update size
    w=@gp.get_attribute("BuildingBlock","bd_width")
    d=@gp.get_attribute("BuildingBlock","bd_depth")
    h=@gp.get_attribute("BuildingBlock","bd_height")
    size=[w,d,h]
    BH_Interact.set_bd_size(@gp,size)
  end

  def update_dialog_data(dlg)
    dict = @gp.attribute_dictionary("BuildingBlock")
    return if dict.class != Sketchup::AttributeDictionary
    dict.keys.each{|key|
      skey=key.to_s
      sval=dict[key].to_s
      message="setValue(#{skey},#{sval})"
      p "sending message: #{message}"
      dlg.execute_script(message)
    }
  end
end
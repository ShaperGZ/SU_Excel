module SUExcel
  def self.open_interaction
    dialog=WD_Interact.create_or_get(WD_Interact.name)
    dialog.open
  end
end

class  WD_Interact < SUExcel::WebDialogWrapper

  attr_accessor :subject

  def self.create_or_get(name)
    dialog=SUExcel::WebDialogWrapper.get(WD_Interact.name)
    if dialog == nil
      name=WD_Interact.name
      dialog=WD_Interact.new(name)
    end
    return dialog
  end

  def initialize(name)
    super(name)
    @subjectGP=nil
    @subjectBB=nil
    @subjectIT=nil
    @dlg=nil
  end


  def open()
    return if @visible
    @dlg = UI::WebDialog.new("AttributeInfo", true, "Information", 739, 641, 150, 300, true)
    file = File.join(__dir__,"/dialogs/dialog_interact.html")
    @dlg.set_file(file)
    @dlg.set_on_close{close()}
    @dlg.show
    @dlg.add_action_callback("updateAttr"){|dialog,params|update_attr(params)}
    @visible=true
    onSelectionBulkChange(Sketchup.active_model.selection)
  end

  def close()
    @dlg == nil
    @visible = false
  end

  def onSelectionBulkChange(selection)
    if selection.size != 1
      close
      return
    end
    entity = selection[0]

    if entity.class != Sketchup::Group or entity.get_attribute("BuildingBlock","bd_ftfh") == nil
      _send_to_html("selection is not a smart object")
      return
    end

    @subjectGP=entity
    @subjectBB=BuildingBlock::created_objects[entity]
    @subjectIT=@subjectBB.get_updator_by_type(BH_Interact)
    @subjectIT.update_dialog_data(@dlg)
  end

  # def update_attr(params)
  #   trunks=params.split('|')
  #   name=trunks[0]
  #   value=trunks[1]
  #
  #   p("update_attr name=#{name} value=#{value}")
  # end

  def update_attr(params)
    trunks=params.split('|')
    key=trunks[0]
    value=_convert_num_param(trunks[1])

    gp=@subjectGP
    gp.set_attribute("BuildingBlock",key,value)

    # update size
    w=gp.get_attribute("BuildingBlock","bd_width")
    d=gp.get_attribute("BuildingBlock","bd_depth")
    h=gp.get_attribute("BuildingBlock","bd_height")
    size=[w,d,h]
    BH_Interact.set_bd_size(gp,size)
  end

  def _convert_num_param(val)
    trunks=val.split(',')
    if trunks.size==1
      return val.to_f
    else
      result=[]
      trunks.each{|n| result<<n.to_f}
      return result
    end
  end

end
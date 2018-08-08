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
    p 'wd.interact adding action callback'
    @dlg.add_action_callback("updateAttr"){|dialog,params|update_attr(params)}
    @dlg.add_action_callback("normal_mode"){|dialog,params|normal_mode()}
    @dlg.add_action_callback("unit_mode"){|dialog,params|unit_mode()}
    @dlg.add_action_callback("update_all"){|dialog,params|update_all(params)}
    @dlg.add_action_callback("def_reload"){|dialog,params|def_reload(params)}
    @visible=true
    onSelectionBulkChange(Sketchup.active_model.selection)
  end

  def close()
    @dlg == nil
    @visible = false
  end

  def onSelectionBulkChange(selection)
    if selection.size != 1
      return
    end
    entity = selection[0]

    if entity.class != Sketchup::Group or entity.get_attribute("BuildingBlock","bd_ftfh") == nil
      p "selection is not a smart object"
      #_send_to_html("selection is not a smart object")
      return
    end

    @subjectGP=entity
    @subjectBB=BuildingBlock::created_objects[entity]
    @subjectIT=@subjectBB.get_updator_by_type(BH_Interact)
    @subjectIT.set_dlg(@dlg)
    @subjectIT.update_dialog_data()
  end

  def normal_mode()
    p 'switching to normal mode'
    return if @subjectGP==nil or @subjectBB ==nil
    display_mode=@subjectBB.get_updator_by_type(BH_Apt_DisplayMode)
    display_mode.show(false) if display_mode != nil
  end

  def unit_mode()
    p 'switching to unit mode'
    return if @subjectGP==nil or @subjectBB ==nil
    display_mode=@subjectBB.get_updator_by_type(BH_Apt_DisplayMode)
    display_mode.show() if display_mode != nil
  end

  def update_attr(params)
    p "wd_interact.update_attr #{params}"
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

  def update_all(params)
    p "update all attr from wd message= #{params}"
    gp=@subjectGP
    trunks=params.split(',')
    trunks.each{|pair|
      pair_items=pair.split(':')
      key=pair_items[0]
      val=pair_items[1]
      gp.set_attribute("BuildingBlock",key,_convert_num_param(val))
    }

    w=gp.get_attribute("BuildingBlock","bd_width")
    d=gp.get_attribute("BuildingBlock","bd_depth")
    h=gp.get_attribute("BuildingBlock","bd_height")
    size=[w,d,h]
    update=BH_Interact.set_bd_size(gp,size)
    if not update
      bd=BuildingBlock.created_objects[gp]
      bd.invalidate()
    end

  end

  def def_reload(param)
    p "loading definition..."
    Definitions.reload()
    p "def lodaded: #{Definitions.defs}"
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
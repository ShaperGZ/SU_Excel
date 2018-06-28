#英寸转米 系数
$m2inch=39.3700787
$m2inchsq=1550.0031

$genName="SCRIPTGENERATEDOBJECTS"
def hideSGO()
  modelEnts=Sketchup.active_model.entities 
  modelEnts.each{|e| e.hidden=true if e.name==$genName}
end
def showSGO()
  modelEnts=Sketchup.active_model.entities 
  modelEnts.each{|e| e.hidden=false if e.name==$genName}
end
def setApt()
  sel=Sketchup.active_model.selection
  sel.each{|e| e.name="zone1_t1_apartment_3"}
end
def setOffice()
  sel=Sketchup.active_model.selection
  sel.each{|e| e.name="zone1_t1_office_4,5"}
end

def setArea(newArea,axis=0)
  return if Sketchup.active_model.selection.size!=1
  entity=Sketchup.active_model.selection[0]
  orgArea=entity.get_attribute("BuildingBlock","area")
  return if orgArea == nil
  ratio=newArea / orgArea
  scales=[1,1,1]
  scales[axis]=ratio
  tr=Geom::Transformation.scaling(scales[0],scales[1],scales[2])
  entity.transform! tr
end




class InstCalAreaAction < Sketchup::InstanceObserver
  def initialize(updater)
    @updater=updater
  end
  def onOpen(instance)
  end
  def onClose(instance)
    #@updater.constrain_all()
    @updater.invalidate()
    SUExcel.data_manager.onChangeEntity(instance)

  end
end

class EntsCalAreaAction < Sketchup::EntitiesObserver
  def initialize(updater)
    @updater=updater
  end
  def onElementAdded(entities, entity)
    #puts "onElementAdded: #{entity}"
  end
  def onElementModified(entities, entity)
    #puts "onElementModified: #{entity}"
    #@updater.constrain_one_faceZ(entity) if entity.class==Sketchup::Face and entity.normal.z==1
  end
end

class GrpCalAreaAction < Sketchup::EntityObserver
  def initialize(updater)
    @updater=updater
  end

  def onEraseEntity(entity)
    @updater.removeCuts()
    SUExcel.data_manager.onDelete(entity)
    SUExcel.update_data_note()
  end

  def onChangeEntity(entity)
	begin
		if entity.entities.size != nil
		  ftfh = entity.name.split('_')[3].to_f   #提取层高
		  entity.set_attribute("BuildingBlock","ftfh",ftfh)
		  @updater.invalidate()
		  SUExcel.data_manager.onChangeEntity(entity)
		end
	rescue Exception
		p "Exception, To be discovered"
	end
	
  end
end

class AreaUpdater
  attr_accessor :gp
  @@created_objects=Hash.new
  def self.created_objects
    @@created_objects
  end

  def self.include? (guid)
    return @@created_objects.keys?(guid)
  end

  #create a new AreaUp if not already created
  # invalidate if exist
  def self.create_or_invalidate(g)
    if @@created_objects.key?(g.guid)
      @@created_objects[g.guid].invalidate
    else
      AreaUpdater.new(g)
    end
  end
  
  def self.remove_deleted()
    hs=@@created_objects
    hs.keys.each{|k| 
	  gp=hs[k].gp
	  hs.delete(k) if gp==nil or gp.deleted?
	  }
  end

  def initialize(group)
    @gp=group
    if @@created_objects.key?(group.guid) ==false
      attrdicts = group.attribute_dictionaries
      begin
        group.get_attribute("BuildingBlock","ftfh")
      rescue Exception
        group.set_attribute("BuildingBlock","ftfh",group.name.split('_')[3].to_f)
      end
      group.add_observer(InstCalAreaAction.new(self))
      group.add_observer(GrpCalAreaAction.new(self))
      #group.entities.add_observer(EntsCalAreaAction.new(self))
      @@created_objects[group.guid]=self
    end

    invalidate()
  end

  def invalidate()
	constrain_all()
    entity=@gp
    p "invalidateing #{entity}"
    removeCuts()
    ftfh=entity.get_attribute("BuildingBlock","ftfh")
    floors = cutFloor(entity,ftfh)
    @cuts = intersectFloors(entity,floors)
    if @cuts == nil
      return
    end
    @cuts.locked =true
    @cuts.name=$genName
    ttArea=calAreas()
    entity.set_attribute("BuildingBlock","area",ttArea)
  end

  # subject:组
  # ftfh:层高
  # foffset=0.6:一般面积是从离地600mm开始算
  def cutFloor(subject ,ftfh, foffset=1)

    modelEnts=Sketchup.active_model.entities 
    cutter=modelEnts.add_group
    cutEnts=cutter.entities
    cutTrans=cutter.transformation
    #p subject.class
    subjectBound=subject.bounds
    subjectH = (subjectBound.max.z - subjectBound.min.z) 
    #p "(", subjectH
    subjectH =  subjectH / $m2inch
    #p subjectH, ")"

    flrCount = (subjectH / ftfh).floor

    #按逆时针顺序提取boundingbox底部的四个点
    basePts=[
      subjectBound.corner(0)+(subjectBound.corner(0)-subjectBound.corner(3)),
      subjectBound.corner(1)+(subjectBound.corner(1)-subjectBound.corner(2)),
      subjectBound.corner(3)+(subjectBound.corner(3)-subjectBound.corner(0)),
      subjectBound.corner(2)+(subjectBound.corner(2)-subjectBound.corner(1))
      ]

    for i in 0..flrCount
      if basePts[0].z<subjectBound.max.z and (basePts[0].z+(1* $m2inch))<subjectBound.max.z
        f=cutter.entities.add_face(basePts)
        #sketchup 会把在0高度的面自动向下，所以要反过来
        f.reverse! if basePts[0].z==0
        ext=f.pushpull(foffset* $m2inch)
        basePts.each{|p| p.z=p.z+(ftfh * $m2inch)}
      end
    end

    return cutter
  end

  def intersectFloors(subject,floors)
    modelEnts=Sketchup.active_model.entities
    dup=subject.copy
    cuts=floors.intersect(dup)
    if cuts==nil
      dup.erase!
      floors.erase!
    end
    return cuts
  end

  def calAreas()
    ttArea=0
    @cuts.entities.each{|e| ttArea += e.area if e.class == Sketchup::Face and e.normal.z==1 }
    ttArea = ttArea / $m2inchsq
    return ttArea
  end

  def removeCuts()
    return if @cuts == nil or @cuts.deleted?
    @cuts.locked=false
    @cuts.erase!
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
      p e
      constrain_one_faceZ(e) }
  end
  
  
end




 



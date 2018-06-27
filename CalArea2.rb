#英寸转米 系数
$convertion=39.3700787
$convertionSQ=1550.0031

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

def satisfy(name)
  if (name.include? "_") and (name.split('_').size > 3)
    return true
  else
    return false
  end
end

class InstCalAreaAction < Sketchup::InstanceObserver
  def initialize(updater)
    @updater=updater
  end
  def onOpen(instance)
  end
  def onClose(instance)
   @updater.invalidate(instance)
   $dataManager.onChangeEntity(instance) if satisfy(instance.name)
  end
end

class InitialSend
  def sendEntity(entity)
    puts "名字：#{entity.name}"
    puts "ID:#{entity.guid}"
    if satisfy(entity.name) and entity.entities.size != nil
      ftfh = entity.name.split('_')[3].to_f   #提取层高
      entity.set_attribute("BuildingBlock","ftfh",ftfh)
      $dataManager.onChangeEntity(entity)
      puts "发送完成"
    end
  end
end

class GrpCalAreaAction < Sketchup::EntityObserver
  def initialize(updater)
    @updater=updater
  end

  def onEraseEntity(entity)
    @updater.removeCuts()
    $dataManager.onDelete(entity)
    $dataManager.update_data_note()
  end

  def onChangeEntity(entity)
    if satisfy(entity.name) and entity.entities.size != nil
      ftfh = entity.name.split('_')[3].to_f   #提取层高
      entity.set_attribute("BuildingBlock","ftfh",ftfh)
      @updater.invalidate(entity)
      $dataManager.onChangeEntity(entity)
    end
  end
end

class AreaUpdater 
  def initialize(group)
    #@host=group
    @cuts=nil
    group.set_attribute("BuildingBlock","ftfh",group.name.split('_')[3].to_f)
    group.add_observer(InstCalAreaAction.new(self))
    group.add_observer(GrpCalAreaAction.new(self))
    invalidate(group) if satisfy(group.name)
  end

  def invalidate(entity)
    $enableOnEntityAdded=false
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
    $enableOnEntityAdded = true
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
    subjectH =  subjectH / $convertion 
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
      if basePts[0].z<subjectBound.max.z and (basePts[0].z+(1* $convertion))<subjectBound.max.z
        f=cutter.entities.add_face(basePts)
        #sketchup 会把在0高度的面自动向下，所以要反过来
        f.reverse! if basePts[0].z==0
        ext=f.pushpull(foffset* $convertion)
        basePts.each{|p| p.z=p.z+(ftfh * $convertion )}
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
    ttArea = ttArea / $convertionSQ
    return ttArea
  end

  def removeCuts()
    return if @cuts == nil
    @cuts.locked=false
    @cuts.erase!
  end
end




 



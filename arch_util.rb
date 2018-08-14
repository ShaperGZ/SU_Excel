$m2inch=39.3700787
$m2inchsq=1550.0031
$genName="SCRIPTGENERATEDOBJECTS"

module ArchUtil

  def ArchUtil.copy_entities(ents)
    dups=[]
    ents.each{|e|
      dups<< e.copy if e!=nil and e.valid? and (e.class ==Sketchup::Group or e.class ==Sketchup::ComponentInstance)
    }
    return dups
  end

  # input gps: list of groups
  # output is a group as result of a union of all input groups
  def ArchUtil.union_groups(igps,duplicate=true)

    gps=[]
    igps.each{|e|
      next if (
          e ==nil or
          not(e.class ==Sketchup::Group or e.class ==Sketchup::ComponentInstance) or
          !e.valid?
      )
      gps<<e
    }
    return nil if gps.size==0

    if duplicate
      g0=gps[0].copy
    else
      g0=gps[0]
    end
    for i in 1..gps.size-1
      # p "joining gps. i=#{i} gps[0]=#{gps[0]} g0=#{g0} "
      if duplicate
        g1=gps[i].copy
      else
        g1=gps[i]
      end
      u=g0.union(g1)
      g0=u if u != nil
    end

  return g0
end

  def ArchUtil.intersect(g1,g2,container)
    result=g1.entities.intersect_with(
        true,
        g1.transformation,
        container,
        container.transformation,
        true,
        g2
    )
    return result
  end

  def ArchUtil.add_box(pos,size,grouped=true,container=nil,unscalled=true, alignment=Alignment::SW)
    container = Sketchup.active_model if container == nil
    if grouped
      gp = container.entities.add_group
    else
      gp = container
    end


    xvect=Geom::Vector3d.new(1,0,0)
    zvect=Geom::Vector3d.new(0,0,1)
    yvect=zvect.cross(xvect)

    if unscalled
      size[0] /= container.transformation.xscale
      size[1] /= container.transformation.yscale
      size[2] /= container.transformation.zscale
    end

    xvect.length=size[0]
    yvect.length=size[1]
    zvect.length=size[2]  if size[2]!=0
    halfx=xvect.clone
    halfx.length=xvect.length/2
    halfy=yvect.clone
    halfy.length=halfy.length/2

    case(alignment)
    when Alignment::SW
      org = pos
    when Alignment::SE
      org = pos - xvect
    when Alignment::NW
      org = pos - yvect
    when Alignment::NE
      org = pos - xvect - yvect
    when Alignment::S
      org = pos - halfx
    when Alignment::N
      org = pos - halfx - yvect
    when Alignment::W
      org = pos - halfy
    when Alignment::E
      org = pos - halfx - xvect
    else
      org = pos - halfx - halfy
    end

    pts=[]
    pts<<org
    pts<<pts[0]+xvect
    pts<<pts[1]+yvect
    pts<<pts[0]+yvect

    f=gp.entities.add_face(pts)
    f.reverse! if f.normal.z<0
    f.pushpull(zvect.length) if size[2]!=0


    return gp
  end

  def ArchUtil.local_cut_face(gp,axis=2,gen_face=true)
    subject=gp
    subjectBound=subject.local_bounds

    # 按逆时针顺序提取boundingbox底部的四个点
    # 后面加的括号里的向量是为了拿大个plane
    basePts=[]
    case axis
    when 1
      indices=[4,5,1,0]
      shift=[1,0,4,5]
    when 0
      indices=[0,2,6,4]
      shift=[6,4,0,2]
    else
      indices=[0,1,3,2]
      shift=[3,2,0,1]
    end
    for i in 0..3
      idx=indices[i]
      sht=shift[i]
      basePts<<subjectBound.corner(idx)+(subjectBound.corner(idx)-subjectBound.corner(sht))
    end
    if gen_face
      g=Sketchup.active_model.entities.add_group
      g.entities.add_face(basePts)
      g.transformation=subject.transformation
      return g
    end
    return basePts
  end

  def ArchUtil.local_cut_face_array(gp, distances, axis=2, gen_face=true, container=nil, reverse=false)
    pts=ArchUtil.local_cut_face(gp,axis,false)
    if axis==2
      pts.each{|p| p[2]=0}
    end
    pts_array=[]
    vect=Geom::Vector3d.new(0,0,0)
    vect[axis]=1
    if reverse
      reverse=-1
    else
      reverse=1
    end

    scales=[1,1,1]
    if container != nil
      scales[0]=container.transformation.xscale
      scales[1]=container.transformation.yscale
      scales[2]=container.transformation.zscale
    end


    distances.each{|d|
      ipts=pts.clone
      add_vect=vect.clone
      add_vect.length=d / scales[axis]
      add_vect.length *= reverse
      for i in 0..ipts.size-1
        ipts[i] += add_vect
      end
      # p "ipts.z=#{ipts[2]} add_vect=#{add_vect}"
      pts_array<<ipts
    }

    if gen_face
      if container != nil
        g=container.entities.add_group
      else
        g=Sketchup.active_model.entities.add_group
      end

      pts_array.each{|pts|
        g.entities.add_face(pts)
      }
      g.transformation=gp.transformation if container!=gp
      return g
    end

    return pts_array
  end

  def ArchUtil.Transformation_scale_3d(scale_array=[1,1,1])
    x=scale_array[0]
    y=scale_array[1]
    z=scale_array[2]

    a=[
        x,0,0,0,
        0,y,0,0,
        0,0,z,0,
        0,0,0,1
    ]

    t=Geom::Transformation.new()
    t.set!(a)
    return t
  end

  def ArchUtil.scale_3d(gp,scale_array=[1,1,1])
    t=ArchUtil.Transformation_scale_3d(scale_array)
    gp.transformation *= t
  end


  def ArchUtil.translate(ent,pos)
    t=Geom::Transformation.translation([pos.x, pos.y, pos.z])
    ent.transform! t
  end

  def ArchUtil.getVerts(ents)
    verts=[]
    ents.each{|e|
      if e.class == Sketchup::Edge
        e.vertices.each{|v|
          verts<<v if !verts.include?(v)
        }
      end
    }
    verts
  end

  def ArchUtil.remove_coplanar_edges(entities)
    tbr=[]
    entities.each{|e|
      if e.class == Sketchup::Edge and e.faces.size==2
        if e.faces[0].normal == e.faces[1].normal
          tbr<<e
        end
      end
    }

    for i in 0..tbr.size-1
      tbr[i].erase! if tbr[i].valid?
    end
  end



  def ArchUtil.genFlrPlns(ent,ftfh=3)
    modelEnts=Sketchup.active_model.entities
    cutter=modelEnts.add_group
    cutEnts=cutter.entities
    cutTrans=cutter.transformation
    cutter.transform! Geom::Transformation.translation([0,0,1.m])

    subject=ent
    return nil if subject == nil
    subjectBound=subject.bounds
    subjectH = (subjectBound.max.z - subjectBound.min.z)
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
        #ext=f.pushpull(foffset* $inch2m)
        basePts.each{|p| p.z=p.z+(ftfh * $m2inch )}
      end
    end
    cutter.transform! Geom::Transformation.translation([0,0,-1.m])
    return cutter
  end

  def ArchUtil.getIntersectPlanes(ent,plns)

    xpln=Sketchup.active_model.entities.add_group
    def ArchUtil.intersectFace(ent,pln,gp)
      ent.entities.intersect_with(
          true,
          ent.transformation,
          gp,
          gp.transformation,
          true,
          pln
      )
      edge=gp.entities[gp.entities.size-2]
      edge.find_faces if edge != nil
      return gp
    end

    plns.entities.each{|p| intersectFace(ent,p,xpln)}
    return xpln
  end

  def ArchUtil.getIntersectSolidPlanes(ent,plns,thickness=0.8)
    thickness *= $m2inch
    faces=[]
    plns.entities.each{|e| faces<<e if e.class == Sketchup::Face}
    faces.each { |e| e.pushpull(thickness)}
    xpln = plns.intersect(ent)
    return xpln
  end

  def ArchUtil.invalidated_transformation?(t1,t2)
    result=[false,false,false]
    result[0]=true if (  t1.origin != t2.origin)
    result[1]=true if (  t1.rotx != t2.rotx or
                          t1.roty != t2.roty or
                          t1.rotz != t2.rotz)
    result[2]=true if (  t1.xscale != t2.xscale or
                          t1.yscale != t2.yscale or
                          t1.zscale != t2.zscale)
    return result
  end

  def ArchUtil.equal_transformation?(t1,t2,position=true,rotation=true,scale=true)
    return false if position and (t1.origin != t2.origin)
    return false if rotation and (t1.rotx != t2.rotx or
                                  t1.roty != t2.roty or
                                  t1.rotz != t2.rotz)

    return false if scale and ( t1.xscale != t2.xscale or
                                t1.yscale != t2.yscale or
                                t1.zscale != t2.zscale)
    return true
  end

  def ArchUtil.genFlrsSlow(ent,ftfh=3,thickness=0.8)
    plns=genFlrPlns(ent,ftfh)
    if plns==nil
      p '!Intersection failed'
      return nil
    end
    translate(plns,0,0,1)
    flrs=getIntersectPlanes(ent,plns)
    plns.erase!
    offset=0
    offset=thickness.abs if thickness<0
    translate(flrs,0,0,-1+offset)
    tt_area=0
    faces=[]
    flrs.entities.each{|e| faces<<e if e.class == Sketchup::Face}

    thickness=thickness.abs
    for i in 0..faces.size-1
      f=faces[i]
      tt_area += f.area
      f.pushpull(thickness*$m2inch)
    end

    return [flrs,tt_area/$m2inchsq]
  end

  def ArchUtil.genFlrs(ent,ftfh=3,thickness=0.8)
    plns=genFlrPlns(ent,ftfh)
    if plns==nil
      #p '!Intersection failed'
      return nil
    end
    flrs=getIntersectSolidPlanes(ent.copy,plns,thickness)

    #translate(flrs,0,0,-thickness)
    tt_area=0
    faces=[]
    flrs.entities.each{|e| faces<<e if e.class == Sketchup::Face and e.normal.z==1}

    thickness=thickness.abs
    for i in 0..faces.size-1
      f=faces[i]
      tt_area += f.area
    end

    return [flrs,tt_area/$m2inchsq]
  end

  def ArchUtil.getEntsByIDs(entities, ids)
    ents=[]
    entities.each{|e|
      ents<<e if ids.include?(e.entityID)
    }
    return nil if ents.size<1
    return ents
  end

  def ArchUtil.getEntByID(entities, id)
    entities.each{|e|
      return e if e.entityID==id
    }
    return nil
  end

  def ArchUtil.getMaterial(name)
    mats=Sketchup.active_model.materials
    for i in 0..mats.size-1
      return mats[i] if mats[i].name == name
    end
    return nil
  end

  def ArchUtil.addMaterial(name,repeat=false)
    mats=Sketchup.active_model.materials
    if repeat
      return mats.add name
    else
      m=getMaterial(name)
      m=mats.add name if m == nil
      return m
    end
  end

  def ArchUtil.remove_ents(ents)
    for i in 0..ents.size-1
      ents[i].erase! if ents[i]!=nil and ents[i].valid?
    end
  end

  def ArchUtil.setTextureMaterial(name,texturePath,sizeX=1,sizeY=1)
    m=addMaterial(name)
    m.texture=texturePath
    sizeX *= $m2inch
    sizeY *= $m2inch
    m.texture.size=[sizeX,sizeY]
    return m
  end

  def ArchUtil.makeBox(pos,w,d,h)
    w*=$m2inch
    d*=$m2inch
    h*=$m2inch
    pts=[]
    pts[0]=Geom::Point3d.new(0,0,0)
    pts[1]=pts[0] + [w,0,0]
    pts[2]=pts[1] + [0,d,0]
    pts[3]=pts[0] + [0,d,0]

    gp=Sketchup.active_model.entities.add_group
    ArchUtil.translate(gp,pos)
    f=gp.entities.add_face(pts)
    f.reverse!
    f.pushpull(h)
    return gp
  end

  def ArchUtil.constrainFace(f,step)
    step *= $m2inch
    p "step=#{step}"
    vpos=f.vertices[0].position
    normal = f.normal
    if normal.x.abs==1
      length=vpos.x
    elsif normal.y.abs==1
      length=vpos.y
    else normal.z==1
      length=vpos.z
    end

    remain = length%step
    half = step / 2
    p " length=#{length}, step=#{step}, remain=#{remain}, half=#{half}"
    offset=0
    if remain>=half
      offset=step-remain
    else
      offset=-remain
    end
    f.pushpull(offset)
  end


end

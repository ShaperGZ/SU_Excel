$m2inch=39.3700787
$m2inchsq=1550.0031
$genName="SCRIPTGENERATEDOBJECTS"

module ArchUtil
  # input gps: list of groups
  # output is a group as result of a union of all input groups
  def ArchUtil.union_groups(igps)
    gps=[]
    igps.each{|e|
      gps<<e if e!=nil and e.class==Sketchup::Group and e.valid?
    }

    g0=gps[0].copy
    for i in 1..gps.size-1
      g1=gps[i].copy
      g0=g0.union(g1)
    end
    
    return g0
  end

  def ArchUtil.translate(ent,x,y,z)
    t=Geom::Transformation.translation([x*$m2inch, y*$m2inch, z*$m2inch])
    ent.transform! t
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
    entities.each{|e|
      if e.class == Sketchup::Edge
        planar=true
        ref=e.faces[0].normal
        e.faces.each{|f|
          if f.normal != ref
            planar=false
            break
          end
        }
        if planar
          e.erase!
        end
      end
    }
  end

  def ArchUtil.get_edge_normal(edge, abs=false, normalize=true)
    vs=edge.vertices
    n=vs[1].position-vs[0].position
    n.length=1 if normalize
    if abs
      n=Geom::Vector3d.new(n.x.abs,n.y.abs,n.z.abs)
    else
      n=Geom::Vector3d.new(n.x,n.y,n.z)
    end
    n
  end

  def ArchUtil.genFlrPlns(ent,ftfh=3)
    modelEnts=Sketchup.active_model.entities
    cutter=modelEnts.add_group
    cutEnts=cutter.entities
    cutTrans=cutter.transformation

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

    return cutter
  end

  # intersect g1 with g2, and put the resulted lines in container
  def ArchUtil.intersect(g1,g2,container)
    g1.entities.intersect_with(
        true,
        g1.transformation,
        container,
        container.transformation,
        true,
        g2
    )
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

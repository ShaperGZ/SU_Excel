#require 'Matrix'

module ArchUtil
  $index = 39.37007874015749
  def ArchUtil.get_quad_verts(f)
    if f.class != Sketchup::Face or f.vertices.size !=4
      p 'given entity is not a face or vertices number not equals 4!'
      return
    end
    pts=[]
    f.vertices.each{|v|
      pts<<v.position
    }
    return ArchUtil.sort_quad_verts(pts)
  end

  # 按四边形法线所指的逆时针方向提取点
  def ArchUtil.sort_quad_verts(pts)
    # 大目的A，找出起始点便可连出全部点
    # find the the lowest point, it could be one of the two
    pts
    lowest_v=pts[0]

    pts.each{|v|
        lowest_v=v if v.z <= lowest_v.z
        #p "compare v.z=#{v.z} , (#{lowest_v.z})"
        }

    # check if the next pt from the 'lowest point' is a bottom point
    # if it is, the 'lowest point' is teh starting point
    # else the previous point is the start point
    i=pts.index(lowest_v)
    if i+1 >= pts.size
      j = 0
    else
      j = i + 1
    end
    next_v = pts[j]

    if next_v.z > lowest_v.z
      start_index = i-1
      start_index = pts.size - 1 if start_index<0
    else
      start_index = i
    end

    # from start point extract all vertices in a loop
    sorted=[]
    index=start_index
    for i in 0..3
      sorted << pts[index]
      #p "adding index: #{index}"
      index+=1
      index -= 4 if index >= pts.size
    end
    return sorted
  end

  def ArchUtil.get_quad_vects(f,normalized=false)
    verts=ArchUtil.get_quad_verts(f)
    return nil,nil if verts == nil

    vectx=(verts[1]-verts[0])
    vectz=(verts[3]-verts[0])

    if normalized
      return vectx.normalize, vectz.normalize
    end
    return vectx,vectz
  end

  def ArchUtil.get_quad_transform(f)
    verts=ArchUtil.get_quad_verts(f)
    return nil,nil if verts == nil

    vectx=(verts[1].position-verts[0].position)
    uvectx=vectx.normalize
    uvecty=Geom::Vector3d.new(0,0,1).cross(uvectx)
    trans = Geom::Transformation.new(verts[0], uvectx, uvecty)
    return trans
  end

  #========================================================================

  #返回Face的长和高
  def ArchUtil.get_quad_dimension(f)
    verts=ArchUtil.get_quad_verts(f)
    vectx=(verts[1]-verts[0])
    vectz=(verts[3]-verts[0])
    return vectx.length,vectz.length
  end

  #组贴面   问题：当组缩放后，组里的面也会缩放。面的原点位置、边长均会发生改变。目前不知道怎么用程序求得缩放后的组中的面的边长和原点
  def ArchUtil.orient_component_to_face_form_group(c,g)
    return if g.class != Sketchup::Group
    gtr = g.transformation

    #获取不缩放情况下的组的transformation(移动、旋转)
    x = gtr.xaxis
    y = gtr.yaxis
    z = gtr.zaxis
    o = gtr.origin
    tr = Geom::Transformation.axes(o, x, y, z)

    #获取组各轴的缩放系数
    xs = gtr.xscale
    ys = gtr.yscale
    zs = gtr.zscale
    scale = [xs,ys,zs]

    g.entities.each{|e|
      if e.class == Sketchup::Face and e.vertices.size ==4
        ArchUtil.orient_component_to_face(c,e,true,true,true,[scale,tr])
      end
    }
  end

  #仅最后一块适配面
  def ArchUtil.orient_component_to_face_lastone_change(c,f)
    ArchUtil.orient_component_to_face(c,f,true,true,false,nil)
  end

  #平均适配面
  def ArchUtil.orient_component_to_face_scaled(c,f)
    ArchUtil.orient_component_to_face(c,f,true,true,true,nil)
  end

  #尺寸固定
  def ArchUtil.orient_component_to_face_by_counts(c,f,count_u,count_v)
    ArchUtil.orient_component_to_face(c,f,count_u,count_v,false,false,true,nil)
  end

  def ArchUtil.orient_component_to_face(c,f,count_u=0,count_v=0,xscaled,zscaled,is_average,group_info)
    # 把面分成横向 count_u 份， 纵向 count_v 份
    # 把每一份的基点 transform 加入matrix
    # 返回 一堆组件
    pts=ArchUtil.get_quad_verts(f)
    orgin = pts[0]
    vectx=(pts[1]-pts[0])
    vectz=(pts[3]-pts[0])
    uvectx=vectx.normalize
    uvectz=vectz.normalize
    uvecty = Geom::Vector3d.new(0,0,1).cross(uvectx)
    scale_factor = nil
    group_trans = nil
    if(group_info != nil)
      scale_factor = group_info[0]
      group_trans = group_info[1]
    end

    #p "原fL:#{(vectx).length/$index}"
    #p "原fH:#{(vectz).length/$index}"

    #面的长、高
    if(scale_factor != nil)
      f_length = (vectx).length * scale_factor[0]
      f_height = (vectz).length * scale_factor[2]
    else
      f_length = (vectx).length
      f_height = (vectz).length
    end

    #p "现fL:#{f_length/$index}"
    #p "现fH:#{f_height/$index}"

    #组件的长、高
    c_length = c.bounds.width
    c_height = c.bounds.depth
    #默认缩放倍数
    x_multiple = 1
    z_multiple = 1

    #计算切割的份数
    if(count_u == 0)
      count_u = (f_length/c_length).round
      count_u = 1 if count_u<1
      p "count_u:#{count_u}"
    end
    if(count_v ==0)
      count_v = (f_height/c_height).round
      count_v = 1 if count_v<1
      p "count_v:#{count_v}"
    end

    #计算缩放倍数
    if(xscaled==false || is_average==false)
      u = c_length
    else
      u = f_length/count_u
      x_multiple = u/c_length
      #p "x倍数：#{x_multiple}"
    end

    if(zscaled==false || is_average==false)
      v = c_height
    else
      v = f_height/count_v
      z_multiple = v/c_height
      #p "z倍数：#{z_multiple}"
    end

    #余数
    remainder =  f_length - (count_u*u)

    #将orgin的Point3d转化为Vector3d
    orgin_vector =  Geom::Point3d.new(0,0,0).vector_to(orgin)

    point = []
    point << orgin
    vx = []
    vz = []
    remain = []

    if(count_u>1)
      for i in 1..count_u
        uvectx_new = Geom::Vector3d.new(uvectx.x*u*i,uvectx.y*u*i,uvectx.z*u*i)
        x_vector = uvectx_new+orgin_vector

        if(i == count_u)
          remain << Geom::Point3d.new(x_vector.x,x_vector.y,x_vector.z) if !is_average
        else
          vx << x_vector
          point << Geom::Point3d.new(x_vector.x,x_vector.y,x_vector.z)
        end
      end
    end

    if(count_v>1)
      for i in 1..count_v
        uvectz_new = Geom::Vector3d.new(uvectz.x*v*i,uvectz.y*v*i,uvectz.z*v*i)
        z_vector = uvectz_new+orgin_vector

        if(i == count_v)
          remain << Geom::Point3d.new(z_vector.x,z_vector.y,z_vector.z) if !is_average
        else
          vz << z_vector
          point << Geom::Point3d.new(z_vector.x,z_vector.y,z_vector.z)
        end
      end
    end

    vx.each{|x|
      vz.each {|z|
        vector = x+z
        pos = vector - orgin_vector
        point << Geom::Point3d.new(pos.x,pos.y,pos.z)
      }
    }

    matrix = []
    point.each{|p|
      tr = Geom::Transformation.new(p, uvectx, uvecty)
      ts = Geom::Transformation.scaling(x_multiple,1,z_multiple)

      model = c.copy
      m = model.transform!(ts).transform!(tr)
      m = m.transform!(group_trans) if group_trans != nil
      p m.class
      matrix << m
    }
    return matrix if is_average

    remain.each{|p|
      tr = Geom::Transformation.new(p, uvectx, uvecty)
      s = remainder/c_length
      ts = Geom::Transformation.scaling(s,1,1)

      m = c.copy.transform!(ts).transform!(tr)
      matrix << m
    }

    return matrix
  end

  def ArchUtil.load_def(file)
    path=SUExcel.get_path(file)
    defs=Sketchup.active_model.definitions
    defs.load(path)
  end

  def ArchUtil.orient_definition_to_face(d,f,igp=nil,container=nil,scaled=true)
    pts=ArchUtil.get_quad_verts(f)
    vx=pts[1]-pts[0]
    vz=pts[3]-pts[0]

    if igp !=nil
      ftfh=igp.get_attribute("BuildingBlock","bd_ftfh")
      ftfh=ftfh[0] if ftfh.class == Array
      countz=(vz.length / ftfh).round
      scaled_sz=vz.length / countz
    else
      countz=(vz.length / unit_size[2]).floor
      scaled_sz=vz.length / countz
    end

    unit_size=d.bounds.max
    countx=(vx.length / unit_size[0]).round
    scaled_sx=vx.length / countx
    scalex=scaled_sx / unit_size[0]

    scaleT=Geom::Transformation.scaling(scalex,1,scalez)
    container=Sketchup.active_model.entities.add_group if container==nil
    container.transformation=igp.transformation if igp!=nil and igp.class == Sketchup::Group

    for i in 0..countz-1
      for j in 0..countx-1
        uvx=vx.normalize
        uvz=vz.normalize
        uvy=uvz.cross(uvx)
        uvx.length=scaled_sx*j
        uvz.length=scaled_sz*i
        pos=pts[0] + uvx + uvz
        t=Geom::Transformation.new(pos,vx.normalize,uvy)
        c=container.entities.add_instance(d,scaleT)
        c.transform!(t)
      end
    end
  end

end



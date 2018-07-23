module ArchUtil

  def ArchUtil.temp()
    $sel=Sketchup.active_model.selection
    widths=[0.5,0.5,3]
    caps=[nil,[5,-5],nil]
    voids=[nil,[3,-3],nil]
    #caps=[nil,nil,nil]
    #voids=[nil,nil,nil]
    ArchUtil.constraint_gp($sel[0],widths,caps,voids)
  end

  # caps=[[xmax,xmin],[ymax,ymin],[zmax,zmin]]
  def ArchUtil.constraint_gp(gp,widths=[1,1,nil],caps=[nil,nil,nil],voids=[nil,nil,nil])

    faces=[[],[],[]]
    gp.entities.each{|e|
      for dir in 0..2
        if widths[dir]!=nil and e.class == Sketchup::Face and e.normal[dir].abs == 1
          faces[dir]<<e if e.valid?
        end
      end
    }
    scales=[]
    scales<<gp.transformation.xscale
    scales<<gp.transformation.yscale
    scales<<gp.transformation.zscale

    for dir in 0..2
      for i in 0..faces[dir].size-1
        if faces[dir][i].valid?
          ArchUtil.constrain_face_dir(faces[dir][i],dir,widths[dir],scales[dir],
                                      caps[dir],voids[dir])
        end

      end
    end
    nil
  end

  def ArchUtil.constrain_face_dir(f,dir,w,scale_factor=1,icap=nil,ivoid=nil)
    if f == nil
      p 'f==nil'
      return
    end

    return if f.class != Sketchup::Face and f.valid? and  f.normal[dir].abs != 1
    return if icap==nil and ivoid==nil and w==nil
    icap=[nil,nil] if icap==nil
    ivoid=[nil,nil] if ivoid==nil
    cap=[nil,nil]
    void=[nil,nil]

    for i in 0..1
      cap[i] = icap[i]*$m2inch/scale_factor if icap[i]!=nil
      void[i] = ivoid[i]*$m2inch/scale_factor if ivoid[i] !=nil
    end

    w*= $m2inch/scale_factor
    pos=f.vertices[0].position
    normal=f.normal[dir]

    if cap[0]!=nil and pos[dir]>cap[0]
      offset=cap[0]-pos[dir]
    elsif cap[1]!=nil and pos[dir]<cap[1]
      offset=cap[1]-pos[dir]
    elsif void[0]!=nil and pos[dir]<void[0] and pos[dir]>void[1] and normal>0
      offset=void[0]-pos[dir]
    elsif void[1]!=nil and pos[dir]>void[1] and pos[dir]<void[0] and normal<0
      offset=void[1]-pos[dir]
    else
      #offset=0
      offset = ArchUtil.get_val_offset(pos[dir].abs,w)
      if f.normal[dir]<0
        offset*=-1
      end
      #p "pffset=#{(offset/$m2inch).round(2)}|#{offset} , pos=#{pos[dir].to_f/$m2inch}, w=#{w/$m2inch}"
    end

    #offset = ArchUtil.get_val_offset(pos[dir].abs,w)
    if f.normal[dir]<0
      offset*=-1
    end
    if offset!=0
      f.pushpull(offset)
    end

  end

  # def ArchUtil.offset_verts(entities,x_dict=nil,y_dict=nil)
  #   if x_dict !=nil
  #     for i in 0..x_dict.size-1
  #       k=x_dict.keys[i]
  #       v=x_dict[k]
  #       p "k=#{k}, v=#{v}"
  #       t=Geom::Transformation.translation(Geom::Vector3d.new(k,0,0))
  #       entities.transform_entities(t, v)
  #     end
  #   end
  #
  #   if y_dict !=nil
  #     for i in 0..y_dict.size-1
  #       k=y_dict.keys[i]
  #       v=y_dict[k]
  #       p "k=#{k}, v=#{v}"
  #       t=Geom::Transformation.translation(Geom::Vector3d.new(0,k,0))
  #       entities.transform_entities(t, v)
  #     end
  #   end
  #
  # end
  #
  # def ArchUtil.sort_verts_by_offset(gp,wu,wv)
  #   wu /= gp.transformation.xscale
  #   wv /= gp.transformation.yscale
  #
  #   verts=ArchUtil.getVerts(gp.entities)
  #   x_dict=Hash.new
  #   y_dict=Hash.new
  #
  #   verts.each{|v|
  #     offset_u,offset_v=ArchUtil.get_pt_offset(v.position,wu,wv)
  #     if x_dict.key?(offset_u)
  #       x_dict[offset_u]<<v if offset_u!=0
  #     else
  #       x_dict[offset_u]=[v] if offset_u!=0
  #     end
  #
  #     if y_dict.key?(offset_v)
  #       y_dict[offset_v]<<v if offset_u!=0
  #     else
  #       y_dict[offset_v]=[v] if offset_u!=0
  #     end
  #   }
  #   return x_dict,y_dict
  # end

  def ArchUtil.get_pt_offset(pt,wu,wv)
    offset_u=ArchUtil.get_val_offset(pt.x,wu)
    offset_v=ArchUtil.get_val_offset(pt.y,wv)
    return offset_u,offset_v
  end

  def ArchUtil.get_val_offset(length,unit_width)
    remain=length % unit_width
    if remain<(unit_width/2)
      offset=-remain
    else
      offset=unit_width-remain
    end
    return offset
  end

end


#ArchUtil.temp
class Op_Dimension
  def self.set_bd_size(gp,size)
    osize=self.get_size(gp)
    scale=[1,1,1]
    for i in 0..2
      scale[i]=size[i]/osize[i]
    end

    ArchUtil.scale_3d(gp,scale)

    gp.set_attribute("BuildingBlock", "bd_width", size[0])
    gp.set_attribute("BuildingBlock", "bd_depth", size[1])
    gp.set_attribute("BuildingBlock", "bd_height", size[2])

  end


  def self.get_size(gp, unscaled_ref=nil, meter=false, round=true)
    # group=gp
    group=gp.entities.add_group
    gp.entities.each{|e|
      group.entities.add_face(e.vertices) if e.class == Sketchup::Face
    }

    height = (group.local_bounds.max.z * gp.transformation.zscale).to_m

    width_max = (group.local_bounds.max.x * gp.transformation.xscale).to_m
    width_min = (group.local_bounds.min.x * gp.transformation.xscale).to_m
    width = width_max-width_min

    depth_max = (group.local_bounds.max.y * gp.transformation.yscale).to_m
    depth_min = (group.local_bounds.min.y * gp.transformation.yscale).to_m
    depth = depth_max - depth_min

    group.erase!

    if unscaled_ref !=nil and unscaled_ref.class==Sketchup::Group
      t=unscaled_ref.transformation
      width *= t.xscale
      depth *= t.yscale
      height *= t.zscale
    end

    if meter
      width= width.to_m
      depth= depth.to_m
      height= height.to_m
    end

    if round
      width=width.round(3)
      depth=depth.round(3)
      height=height.round(3)
    end

    return width,depth,height
  end

  def self.local_bound(gp)
    group=gp.entities.add_group
    gp.entities.each{|e|
      group.entities.add_face(e.vertices) if e.class == Sketchup::Face
    }

    bounds=group.local_bounds
    group.erase!
    return bounds
  end

  def self.is_equal_size(gp,size)
    osize=Op_Dimension.get_size(gp)
    for i in 0..2
      return false if osize[i] != size[i].m
    end
    return true
  end

  def self.divide_length( gp,divs=[3,3],axies=0, repeat_end=true,container=nil,untransformation_ref=nil, delete_input=false)
    # for i in 0..divs.size-1
    #   divs[i] = divs[i].m
    # end

    container = Sketchup.active_model if container == nil
    org=gp.bounds.min


    if untransformation_ref
      scales=[
          untransformation_ref.transformation.xscale,
          untransformation_ref.transformation.yscale,
          untransformation_ref.transformation.zscale
      ]
    else
      scales=[1,1,1]
    end
    # p "scales=#{scales}"
    size=Op_Dimension.get_size(gp, untransformation_ref, groupped=false)
    for i in 0..2
      size[i]
    end
    # p "size=#{size}"
    # get the read divs base on actual size
    adj_divs=[]
    curr=0
    counter=0
    while(curr < size[axies])

      if(counter<divs.size-1)
        index=counter
      else
        index=divs.size-1
      end
      d=(divs[index])
      # p "d=#{d}"
      adj_divs<<d
      curr+=d
      counter+=1
    end



    # create the objects
    geos=[]
    curr=0

    if groupped
      container=container.entities.add_group
    end
    for i in 0..adj_divs.size-1
      s=size.clone
      p=org
      for j in 0..2
        if j==axies
          s[axies]=adj_divs[i].m
        else
          s[j] = s[j].m
        end
      end

      #p s.x.to_m

      if i>0
        v=Geom::Vector3d.new(0,0,0)
        v[axies] = curr
        p += v
      end
      curr+=adj_divs[i].m / scales[axies]
      geo=ArchUtil.add_box(p,s,true,container,true, Alignment::SW)
      geos<<geo
    end
    return container if groupped
    return geos
  end
end
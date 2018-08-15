module Generators

  class SpatialGenerator
    attr_accessor :host
    def initialize(host)
      @host=host
      @gp=@host.host.gp
      @enable=true
      # p "on initialize gp=#{@gp}"
      @generated_objs=[]
    end


    def enable(flag=true)
      # p "SpatialGenerator.enable = #{flag}"
      if @enable == flag
        return
      end
      if @generated_objs!=nil and @generated_objs.size>0
        @generated_objs.each{|o|
          if o!=nil and o.valid?
            if flag
              o.hidden=false if o.hidden?
            else
              o.hidden=true
            end
          end
        }
      end
      @enable=flag
    end

    def clear_generated()
      if @generated_objs!=nil and @generated_objs.size>0
        @generated_objs.each{|o|
          if o!=nil and o.valid?
            o.erase!
          end
        }
      end
      @generated_objs=[]
    end

    def generate()
      # override
    end

    def add_geometry(level,geo,type_name)
      geo.set_attribute("BuildingComponent","type",type_name)
      @host.spaces[level]<<geo
    end

    def create_def_holder(params)
      level="level2"
      position=params[0]
      size=params[1]
      defname=params[2]
      create_geometry(level,position,size,defname,Alignment::SW,true)
    end

    def create_geometry(level,position,size,type_name, alignment=Alignment::SW, meter=false, color=nil)
      p=position
      s=size
      t=type_name

      if meter
        for i in 0..2
          p[i]=p[i].m if not p[i].nil?
        end
        for i in 0..s.size-1
          s[i]=s[i].m
        end
      end

      zero=Geom::Point3d.new(0,0,0)
      offset=Geom::Transformation.translation(p)
      comp=ArchUtil.add_box(zero,s,true,@host.gp,true, alignment)
      comp.transformation *= offset
      comp.set_attribute("BuildingComponent","type",t)
      comp.name=type_name
      if color !=nil
        comp.material=color
      end
      @host.spaces[level]<<comp
      return comp
    end

    def attr(key)
      return @host.host.attr(key)
    end

    def get_bd_size()
      w=attr("bd_width")
      d=attr("bd_depth")
      h=attr("bd_height")
      return [w,d,h]
    end

    def get_unit_size()
      val = @host.host.attr("un_prototype")
      if val == nil
        return [3,9]
      end
      p "pre  split 1 va=#{val}"
      trunks = val.split('_')
      str_size = trunks[2].split('x')
      p "post split 1"
      sx = str_size[0].to_f
      sy = str_size[1].to_f
      return [sx,sy]
    end

    def get_inverse_scale()
      sx=@gp.transformation.xscale
      sy=@gp.transformation.yscale
      sz=@gp.transformation.zscale

      return [1.0/sx, 1.0/sy, 1.0/sz]

    end
    def get_scale()
      sx=@gp.transformation.xscale
      sy=@gp.transformation.yscale
      sz=@gp.transformation.zscale

      return [sx,sy,sz]

    end
  end

  class Gen_Apt_Straight < SpatialGenerator
    def initialize(host)
      super(host)
    end

    def generate()
      host=@host

      # 1. get size
      yscale=host.gp.transformation.yscale
      w,d,h=Op_Dimension.get_size(host.gp)
      size=[w,d,h]
      for i in 0..size.size-1
        size[i]=size[i].m
      end

      unit_size=get_un_proto_size()
      # p "unit size = #{unit_size}"

      # 2. generate spaces
      circulation_w=2.m
      pos=[]
      sizes=[]
      types=[]

      local_bounds=Op_Dimension.local_bound(@gp)
      sod = Op_Dimension.single_or_double(size[1].to_m,@gp)
      p " sod = #{sod}"
      if sod=="single"
        rw=(size[1]-circulation_w)
        # rw/=yscale
        # p "rw=#{rw.m}"
        pos<<local_bounds.min
        pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)

        sizes<<[size[0],rw,size[2]]
        sizes<<[size[0],circulation_w,size[2]]

        types=["occupy","clt"]

      else #double
        rw=(size[1]-circulation_w)/2
        # rw/=yscale

        pos<<local_bounds.min
        pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)
        pos<<pos[0]+ Geom::Vector3d.new(0,(rw+circulation_w)/yscale,0)

        sizes<<[size[0],rw,size[2]]
        sizes<<[size[0],circulation_w,size[2]]
        sizes<<[size[0],rw,size[2]]

        types=["occupy","clt","occupy"]
      end

      # 3. get actual geometries
      return if pos.size==0
      zero=Geom::Point3d.new(0,0,0)

      for i in 0..pos.size-1
        g=create_geometry("level1",pos[i],sizes[i],types[i])
        external=false
        external=true if sod == "single"
        g.set_attribute("BuildingComponent","external",external)
      end
    end

    def get_un_proto_size()
      val = @host.host.attr("un_prototype")
      if val == nil
        return [3,9]
      end
      p "pre  split 2"
      trunks = val.split('_')
      str_size = trunks[2].split('x')
      p "post split 2"
      sx = str_size[0].to_f
      sy = str_size[1].to_f
      return [sx,sy]
    end

  end

  class Gen_Cores < SpatialGenerator
    def initialize(host)
      super(host)
    end

    def generate()
      # 1 get circulation, name= "clt"
      circulations= host.get_spaces("level1","clt")

      # p "circulations.size=#{circulations.size}"
      circulations.each{|c|
        external = c.get_attribute("BuildingComponent","external")
        gen_core(c,external)
      }
    end

    def get_color(e)
      if e.class==Sketchup::Group
        ents=e.entities
      elsif e.class == Sketchup::ComponentInstance
        ents=e.definition.entities
      else
        return
      end

      faces=[]
      ents.each{ |f| faces<<f if f.class == Sketchup::Face }
      # p "mat=#{faces[0].material} "
      return faces[0].material
    end

    def load_from_def(position,def_name, alignment=nil, h=0)
      blocks=[]
      d=Definitions.defs[def_name+".skp"]
      return if d == nil
      # get size and cal org
      diagonal=d.bounds.max - d.bounds.min
      size=[1,1,0]
      for i in 0..1
        size[i]=diagonal[i].to_m
      end
      size[2]=h


      scales=[
          host.gp.transformation.xscale,
          host.gp.transformation.yscale,
          host.gp.transformation.zscale
      ]
      # p "position=#{position.x},#{position.y}"


      position=Geom::Point3d.new(position[0].m, position[1].m,0)
      corner_x=d.bounds.min.x
      # p "definition.bounds.min.x=#{corner_x}"
      position.x+=corner_x/scales[0]
      new_corner_x=round_x(position.x)
      position.x=new_corner_x-corner_x

      g = @host.host.gp.entities.add_instance(d,Geom::Transformation.new)
      g.transformation = Geom::Transformation.new

      ts = ArchUtil.Transformation_scale_3d([1/scales[0],1/scales[1],h/scales[2]])
      tt =  Geom::Transformation.translation(position)

      g.name=def_name
      g.transformation *= (ts*tt)

      #g.transform! t0

      @host.spaces["def_blocks"]<<g

      return g
    end

    # round the x position to fit the unit width
    def round_x(w)
      unit_size=get_unit_size
      remain = w  % unit_size[0].m
      nw = w - remain
      return nw
    end

    def gen_core(circulation,external)
      # TODO: once we have abstract components, will
      # get size from abstract components
      bd_width=@host.host.attr("bd_width")
      bd_depth=@host.host.attr("bd_depth")
      bd_height=@host.host.attr("bd_height")

      lift_count=@host.host.attr("apt_lift_count")


      if lift_count == 0
        lift_count=3
      end
      lift_count=lift_count.to_i
      # p "lift_count=#{lift_count})"

      yscale=@host.gp.transformation.yscale
      clt_y=circulation.transformation.origin.y.to_m * yscale
      # p ("clt=#{clt_y} clt.to_s=#{circulation.to_s} clt.size=#{clt_size} clt.class=#{circulation.class}")
      clt_w=2.0
      core_y=clt_y+clt_w

      # 直线板式
      h=bd_height+3
      positions=[]
      sizes=[]
      types=[]
      defs=[]

      evac=15
      width_thresholds=[]
      width_thresholds << evac*2 + 8
      width_thresholds << evac*4
      width_thresholds << width_thresholds[0]+30
      width_thresholds << evac*5
      width_thresholds << evac*6

      if bd_depth < 25
        if bd_width <= width_thresholds[0]
          pos = [bd_width/2,core_y]
          def_name="core_apt_lft_L#{lift_count}_S2"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[1]
          pos = [bd_width/3,core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[(bd_width * 0.75)-3,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[2]
          pos =[15,core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[(bd_width-30)/2 + 30,core_y]
          def_name="core_apt_lft_L#{lift_count}_S2"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[3]
          pos =[15,core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[45,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[bd_width-1.2,core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[4]
          pos =[15,core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[45,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[(45+(bd_width-45)/2.0),core_y]
          def_name="core_apt_str"
          def_name+="_ext" if external and lift_count==3
          defs<<load_from_def(pos,def_name,nil,h)
        end


      end

      # create geometries

      # zero=Geom::Point3d.new(0,0,0)
      # scales=[
      #     host.gp.transformation.xscale,
      #     host.gp.transformation.yscale,
      #     host.gp.transformation.zscale
      # ]


      # for i in 0..positions.size-1
      #   for j in 0..positions[i].size-1
      #     positions[i][j] /= scales[j]
      #   end
      #   p=positions[i]
      #   s=sizes[i]
      #   t=types[i]
      #   p "p=#{p}, s=#{s}, t=#{t}"
      #   create_geometry("level2",p,s,t, Alignment::S,true)
      #
      # end
    end
  end
  class Gen_Cuts < SpatialGenerator
    def initialize(host)
      super(host)
      # p "initialize GenCuts"
      @enable=true
    end

    def generate()
      return if not @enable
      clear_generated()
      unit_size=get_unit_size
      bd_size=get_bd_size
      # p "GenCuts.generate() bd_size=#{bd_size}"
      count=(bd_size[0]/unit_size[0]).ceil
      dists=[]
      for i in 0..count
        if i>0
          d=dists[i-1]+(unit_size[0].m)
        else
          d=unit_size[0].m
        end
        dists<<d
      end
      plnsH = ArchUtil.local_cut_face_array(@gp, dists,0,true, @gp)
      # plnsH.transformation=Geom::Transformation.new

      ftfhs=@host.host.attr("bd_ftfhs")

      dists=[ftfhs[0].m]
      for i in 1..ftfhs.size-2
        dists<<dists[i-1] + ftfhs[i].m
      end
      plnsV=ArchUtil.local_cut_face_array(@gp,dists,2,true, @gp)


      occupy= host.get_spaces("level1","occupy")
      occupy.each{|c|
        ArchUtil.intersect(plnsH,c,c)
        ArchUtil.intersect(plnsV,c,c)
        # ArchUtil.intersect(plns,c,plns)
      }
      plnsH.erase!
      plnsV.erase!
    end
  end

  class Gen_Units < SpatialGenerator
    def initialize(host)
      super(host)

    end

    def enable(flag=true)
      invalidated = true if flag and not @enable
      super(flag)
      clear_generated if not flag
      if invalidated
        generate()
      end
    end

    def generate()
      return if not @enable
      clear_generated()
      model= Sketchup.active_model
      model.start_operation('gen units')

      raise=0.5.m
      un_size=get_unit_size
      bd_size=get_bd_size

      # ////// generate units //////////////////
      occupy= host.get_spaces("level1","occupy")
      # p "occupy.size = #{occupy.size}"
      room_count=0

      for i in 0..occupy.size-1
        c=occupy[i]
        flip=false
        flip =true if i%2!=0
        gen_units(c,flip,raise,bd_size,un_size)
        room_count += gen_room_counts(c)
      end
      # ////// generate circulation ////////////
      clts= host.get_spaces("level1","clt")
      for i in 0..clts.size-1
        clt=clts[i]
        gen_clt(clt,raise,bd_size,un_size)
      end

      @host.host.set_attr("grade_room_count",room_count)
      model.commit_operation
    end



    def gen_room_counts(occupy)
      flrs=@host.host.attr("bd_floors")

      scales=get_scale
      diagonal=occupy.bounds.max-occupy.bounds.min
      size=[1,1,1]
      for i in 0..2
        size[i]=diagonal[i] * scales[0]
      end
      p "occupy size = #{size[0].to_m}"

      un_size=get_unit_size
      unit_count_w=(size[0] / un_size[0].m).round
      return unit_count_w*flrs
    end

    def gen_units(occupy, flipY=false,raise=0,bd_size,un_size)
      # p "#{occupy}.org=#{occupy.bounds.min}------"
      unit_prototype=attr("un_prototype")

      container=@gp.entities.add_group
      # p "added container:#{container}"

      proto=Definitions.instantiate(container,unit_prototype,Geom::Transformation.new)
      if proto==nil
        p "please load skp files into the definitions first"
        return
      end
      unit_count_w=(bd_size[0] / un_size[0]).round
      for i in 0..unit_count_w-1
        offset=Geom::Vector3d.new(i*un_size[0].m,0,0)
        dup=proto.copy
        if i%2 == 0
          offset[0]+=un_size[0].m
          dup.transformation *= Geom::Transformation.translation(offset)
          ArchUtil.scale_3d(dup,[-1,1,1])
        else
          dup.transformation *= Geom::Transformation.translation(offset)
        end
      end

      iscales=get_inverse_scale
      scales=get_scale
      org=occupy.bounds.min
      h=(bd_size[2].m + raise)/scales[2]
      # p "GenUnits.gen_unit() bd_size=#{bd_size} h=#{h.to_m} "
      container.transformation*=Geom::Transformation.translation([0,0,h])
      offset=Geom::Vector3d.new(org.x,org.y,0)
      # offset=Geom::Vector3d.new(org.x,org.y,(bd_size[2].m + raise)/scales[2] )

      if flipY
        iscales[1] *=-1
        offset[1]=occupy.bounds.max.y * -1
      end

      ArchUtil.scale_3d(container,iscales)
      # p "offset.z=#{offset.z.to_m} raise=#{raise.to_m}"
      # p ""
      container.transformation *= Geom::Transformation.translation(offset)


      # container_dup=container.copy
      # ArchUtil.scale_3d(container_dup,[1,-1,1])
      # offset=Geom::Vector3d.new(0,-((2*unit_size[1].m)+2.m),0)
      # container_dup.transformation *= Geom::Transformation.translation(offset)
      # proto.erase!

      @generated_objs<<container
      #@generated_objs<<container_dup
    end
    def gen_clt(clt, raise,bd_size,un_size)
      bot_verts=nil
      scales=get_scale
      clt.entities.each{|e|
        if e.class == Sketchup::Face and e.normal.z==1
          bot_verts=e.vertices
          break
        end
      }
      pts=[]
      bot_verts.each{|v|
        p=v.position
        p.z=0
        pts<<p
      }

      container=@gp.entities.add_group
      f=container.entities.add_face(pts)
      f.reverse! if f.normal.z<0
      container.transformation=clt.transformation
      h=(bd_size[2].m+raise)/scales[2]
      # p "GenUnits.gen_clt() bd_size=#{bd_size} h=#{h.to_m} "
      container.transformation*=Geom::Transformation.translation([0,0,h])
      @generated_objs<<container

    end
  end

  class Decompose_FLBF < SpatialGenerator
    def initialize(host)
      super(host)
    end

    def generate()
      flbf= host.get_spaces("level2","comp_clt")
      # p "flbl.size= #{flbf.size}"
      flbf.each{|c|
        gen_flbf(c)
      }
    end

    def gen_flbf(flbf)
      size=Op_Dimension.get_size(flbf, @host.gp)
      positions=[]
      sizes=[]
      divs=[]
      types=[]
      colors=[]
     # p "gen_flbf size=#{size}"
      scales=[
          host.gp.transformation.xscale,
          host.gp.transformation.yscale,
          host.gp.transformation.zscale
      ]

      org=flbf.bounds.min
      for i in 0..2
        org[i]=org[i].to_m * scales[i]
      end

      if size[0]>=12 and size[0]<15
        varies=size[0]-9
        divs=[3,varies,3,3]

        types<<"f_str"
        types<<"c_lobby"
        types<<"c_lift"
        types<<"f_str"

        colors<<nil
        colors<<'#ffcc22'
        colors<<'#ffaa00'
        colors<<nil

      elsif size[0]>=9 and size[0]<12
        varies=size[0]-6
        divs=[varies,3,3]

        types<<"c_lobby"
        types<<"c_lift"
        types<<"f_str"

        colors<<'#ffcc22'
        colors<<'#ffaa00'
        colors<<nil
      end


      objs=Op_Dimension.divide_length(flbf,divs,0, true, @host.gp,@host.gp)
      for i in 0..objs.size-1
        o=objs[i]
        o.material=colors[i] if colors[i] != nil
        add_geometry("level2",o,types[i])
      end


      @host.erase_space("level2",flbf)
    end

  end

  class Decompose_F_STR < SpatialGenerator
    def initialize(host)
      super(host)
    end

    def generate()
      # 1 get circulation, name= "clt"

      fstr= host.get_spaces("level2","f_str")
      fstr.each{|c|
        gen_fstr(c)
      }
    end

    def gen_fstr(fstr)
      size=Op_Dimension.get_size(fstr, @host.gp)
      varies=size[1]-6.5
      divs=[varies,6.5]
      objs=Op_Dimension.divide_length(fstr,divs,1, true, @host.gp,@host.gp)
      objs[0].material="#cc8888"
      add_geometry("level2",objs[0],"f_strl")
      objs[1].material="#aa0000"
      add_geometry("level2",objs[1],"f_strs")

      @host.erase_space("level2",fstr)
    end
  end

  class Gen_Area < SpatialGenerator
    def initialize(host)
      super(host)
      @trash=[]
    end

    def generate()
      @trash=[]
      host=@host
      pure_objs=host.get_spaces("level1")
      pure_objs+=host.get_spaces("level2")
      pure_objs+=host.get_spaces("level3")

      def_inst=host.get_spaces("def_blocks")
      def_ents=[]
      def_inst.each{|i| def_ents+=get_gpinst(i)}

      area_objs=pure_objs+def_ents
      area_objs = ArchUtil.copy_entities(area_objs)
      area,merged = _join_area(area_objs, @host.gp)
      flrs=@host.host.attr("bd_floors")

      service_objs=[]
      pure_objs.each{|o|
        if o.valid?
          t=o.get_attribute("BuildingComponent","type")
          if t !=nil and t!="occupy"
            service_objs<<o
          end
        end
      }

      service_objs+=def_ents
      service_objs=ArchUtil.copy_entities(service_objs)
      service_area,merged_srv=_join_area(service_objs, @host.gp)
      service_area
      efficiency=(area-service_area)/area
      # p "area=#{area.to_s} service_area=#{service_area}"
      # p "efficiency="+efficiency.to_s

      @host.gp.set_attribute("BuildingBlock","bd_typical_area",area.round(2))
      @host.gp.set_attribute("BuildingBlock","bd_typical_net_area",(area-service_area).round(2))
      @host.gp.set_attribute("BuildingBlock","bd_area",area.round(2)*flrs)
      @host.gp.set_attribute("BuildingBlock","grade_efficiency",efficiency.round(2))

      # clear trash
      @trash<<merged
      @trash<<merged_srv
      @trash+=def_ents
      @trash+=area_objs
      @trash+=service_objs
      ArchUtil.remove_ents( @trash )
    end

    def gen_cuts(merged)

      #create cut planes
      #

    end

    # get groups and instances from within a group
    def get_gpinst(inst)
      dup=inst.copy
      ents=[]
      exploded=dup.explode
      for i in 0..exploded.size-1
        e=exploded[i]
        if e.class == Sketchup::Group or e.class == Sketchup::ComponentInstance
          ents<<e
        else
          e.erase! if e.valid? and (e.class== Sketchup::Edge or e.class==Sketchup::Face)
        end
      end
      return ents
    end

    def _join_area(objs, transform_ref=nil)
      dup=ArchUtil.union_groups(objs,false)
      #p "dup.xscale=#{dup.transformation.xscale}"
      ArchUtil.remove_coplanar_edges(dup.entities)

      faces=[]
      dup.entities.each{|e|
        faces<<e if e.class == Sketchup::Face and e.normal.z==-1
      }

      area=0
      unscaled=Sketchup.active_model.entities.add_group
      t=transform_ref.transformation
      faces.each{|f|
        pts=[]
        for i in 0..f.vertices.size-1
          pts<<(f.vertices[i].position.transform t)
        end

        nf=unscaled.entities.add_face(pts)
        area+=nf.area.to_m.to_m
      }
      # unscaled.transformation *= transform_ref.transformation

      #dup.transformation = Geom::Transformation.translation([200.m,0,0])
      unscaled.erase!
      # dup.erase!
      return area,dup
    end

  end

  class ConstraintSize < SpatialGenerator
    def initialize(host)
      super(host)
      @trash=[]
    end

    def generate()
      "ConstraintSize.generate"
      unit_size=get_unit_size
      return if unit_size==nil

      bd_size=get_bd_size

      offsets=[0,0,0]
      offsets[0] = get_offset(bd_size[0],unit_size[0])
      offset_y=get_y_offset(bd_size[1])
      offsets[2] = get_z_offset(bd_size[2],Op_Dimension.set_ftfhs(@gp))
      p "bd_d=#{bd_size[1]} new_d=#{bd_size[1]+offset_y}"
      p "bd_h=#{bd_size[2]} new_h=#{bd_size[2]+offsets[2]}"

      #constraint z

      if offsets[0].round(6)==0
        return
      end

      for i in [0,2]
        bd_size[i]+=offsets[i]
      end

      p "reset to size=#{bd_size}"
      Op_Dimension.set_bd_size(@gp,bd_size)
      @host.skip_rest=true
    end

    def get_offset(num, width)
      remain = num % width
      half = width/2
      offset=0
      if remain>0
        half=width/2
        if remain < half
          offset= -remain
        else
          offset=width - remain
        end
      end
      return offset
    end
    def get_z_offset(bd_height,ftfhs)
      offset=0
      tth=0
      ftfhs.each{|l| tth+=l}
      p "total ftfhs = #{tth}"
      diff = tth - bd_height
      half=ftfhs[-1]/2
      if diff >0
        if diff>half
          offset = (bd_height - (tth-ftfhs[-1])) * -1
        elsif diff<half
          offset = diff
        end
      elsif diff < 0
        offset=diff
      end
      return offset
    end
    def get_y_offset(bd_depth)
      unit_depth_range=[7,11]
      clt_width=2
      single_min=unit_depth_range[0]+clt_width
      single_max=unit_depth_range[1]+clt_width
      double_min=2*unit_depth_range[0]+clt_width
      double_max=2*unit_depth_range[1]+clt_width

      d=bd_depth
      if (d<=single_min)
        d= single_min
      elsif d>single_max and d<double_min
        half=(double_min-single_max)/2.0
        remain=d-single_max
        if remain < half
          d=single_max
        else
          d=double_min
        end
      elsif d>=double_max
        d=double_max
      end
      offset=d-bd_depth
      return offset
    end
  end

  class Gen_Scores < SpatialGenerator
    def initialize(host)
      super(host)
      @trash=[]
    end

    def generate()
      typical=@host.host.attr("bd_typical_area")
      typical_net=@host.host.attr("bd_typical_net_area")
      sprinkler=("fr_sprinkler")
      if sprinkler
        fire_compartment=3000
      end

      remain=typical_net%fire_compartment
      ratio=1-(remain/fire_compartment)

      p "net=#{typical_net} fr_cmp=#{fire_compartment} scaore=#{ratio}"

    end

  end
end
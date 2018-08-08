module Generators

  class SpatialGenerator
    attr_accessor :host
    def initialize(host)
      @host=host
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
      if color !=nil
        comp.material=color
      end
      @host.spaces[level]<<comp
      return comp
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

      # 2. generate spaces
      circulation_w=2.m
      pos=[]
      sizes=[]
      types=[]

      local_bounds=Op_Dimension.local_bound(host.gp)

      if size[1]<=12.m
        rw=(size[1]-circulation_w)/2
        # rw/=yscale
        p "rw=#{rw.m}"
        pos<<local_bounds.min
        pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)

        sizes<<[size[0],rw,size[2]]
        sizes<<[size[0],circulation_w,size[2]]

        types=["occupy","clt"]

      elsif size[1]<=25.m
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
        create_geometry("level1",pos[i],sizes[i],types[i])
      end
    end

  end


  class Gen_Cores < SpatialGenerator
    def initialize(host)
      @host=host
    end

    def generate()
      # 1 get circulation, name= "clt"
      circulations= host.get_spaces("level1","clt")
      p "circulations.size=#{circulations.size}"
      circulations.each{|c|
        gen_core(c)
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
      p "mat=#{faces[0].material} "
      return faces[0].material
    end

    def load_from_ent(e,org,h)


      diagonal=e.bounds.max - e.bounds.min
      size=[1,1,0]
      for i in 0..1
        size[i]=diagonal[i].to_m
      end
      size[2]=h

      position = [org[0] + e.bounds.min[0].to_m, org[1]+e.bounds.min[1].to_m]


      return [position,size,e.name, get_color(e)]

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
      p "position=#{position.x},#{position.y}"

      position=Geom::Point3d.new(position[0].m, position[1].m,0)

      g = @host.host.gp.entities.add_instance(d,Geom::Transformation.new)
      g.transformation = Geom::Transformation.new

      ts = ArchUtil.Transformation_scale_3d([1/scales[0],1/scales[1],h])
      tt =  Geom::Transformation.translation(position)

      g.transformation *= (ts*tt)

      #g.transform! t0

      @host.spaces["def_blocks"]<<g

      return g
    end

    def gen_core(circulation)
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
      p "lift_count=#{lift_count})"

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
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[1]
          pos = [bd_width/3,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[(bd_width * 0.75)-3,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[2]
          pos =[15,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[(bd_width-30)/2 + 30,core_y]
          def_name="core_apt_lft_L#{lift_count}_S2"
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[3]
          pos =[15,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[45,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[bd_width-1.2,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)

        elsif bd_width <= width_thresholds[4]
          pos =[15,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[45,core_y]
          def_name="core_apt_lft_L#{lift_count}"
          defs<<load_from_def(pos,def_name,nil,h)

          pos =[45+(bd_width-45)/2.0,core_y]
          def_name="core_apt_str"
          defs<<load_from_def(pos,def_name,nil,h)
        end

        # 单边客房
        if bd_depth<=15
          allow_external = @host.host.attr("p_bd_external_core")[0]
          if allow_external

          end

          # 双边客房
        else
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

  class Gen_Units < SpatialGenerator
    def initialize(host)
      @host=host
    end

    def generate()
      model= Sketchup.active_model
      model.start_operation('gen units')

      occupy= host.get_spaces("level1","occupy")
      occupy.each{|c|
        gen_units(c)
      }

      model.commit_operation
    end

    def gen_units(occupy)


      # size=Op_Dimension.get_size(occupy, @host.gp)
      # ftfhs=@host.host.attr("bd_ftfhs")
      # bays=[@host.host.attr("un_width")]
      # levels=Op_Dimension.divide_length(occupy,ftfhs,2, true, @host.gp,@host.gp)
      # objs=[]
      # for i in 0..levels.size-1
      #   l=levels[i]
      #   objs+=Op_Dimension.divide_length(l,bays,0, true, @host.gp,@host.gp)
      #   l.erase!
      # end
      #
      #
      # objs.each{|o|
      #
      #   add_geometry("level2",o,"room_unit")
      # }
    end
  end


  class Decompose_FLBF < SpatialGenerator
    def initialize(host)
      super(host)
    end

    def generate()
      flbf= host.get_spaces("level2","comp_clt")
      p "flbl.size= #{flbf.size}"
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
      p "gen_flbf size=#{size}"
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
      @host=host
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
      @host=host
    end

    def generate()
      objs=host.get_spaces("level1")
      objs+=host.get_spaces("level2")
      objs+=host.get_spaces("level3")
      area = _join_area(objs, @host.gp)
      # area = _join_area(objs)
      @host.gp.set_attribute("BuildingBlock","bd_area",area.round(2))

      service_obj=[]
      occupy_count=0
      objs.each{|o|
        if o.valid?
          t=o.get_attribute("BuildingComponent","type")
          if t !=nil and t!="occupy"
            service_obj<<o
          else
            occupy_count+=1
          end
        end

      }
      p "occupy_count=#{occupy_count}"
      p "@host.gp=#{@host.gp}"
      # service_area=_join_area(service_obj)
      service_area=_join_area(service_obj, @host.gp)
      efficiency=(area-service_area)/area
      p "area=#{area.to_s} service_area=#{service_area}"
      p "efficiency="+efficiency.to_s

      @host.gp.set_attribute("BuildingBlock","grade_efficiency",efficiency.round(2))

    end

    def _join_area(objs, transform_ref=nil)
      dup=ArchUtil.union_groups(objs)
      p "dup.xscale=#{dup.transformation.xscale}"
      ArchUtil.remove_coplanar_edges(dup.entities)
      it=dup.transformation.inverse


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

      unscaled.erase!
      dup.erase!
      return area
    end



  end
end
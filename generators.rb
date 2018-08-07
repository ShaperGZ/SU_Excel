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

        types=["room","clt"]

      elsif size[1]<=25.m
        rw=(size[1]-circulation_w)/2
        # rw/=yscale

        pos<<local_bounds.min
        pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)
        pos<<pos[0]+ Geom::Vector3d.new(0,(rw+circulation_w)/yscale,0)

        sizes<<[size[0],rw,size[2]]
        sizes<<[size[0],circulation_w,size[2]]
        sizes<<[size[0],rw,size[2]]

        types=["room","clt","room"]
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

    def gen_core(circulation)
      # TODO: once we have abstract components, will
      # get size from abstract components
      bd_width=@host.host.attr("bd_width")
      bd_depth=@host.host.attr("bd_depth")
      bd_height=@host.host.attr("bd_height")

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

      if bd_depth < 25
        if bd_width <= 42
          positions<< [bd_width/2,core_y]
          sizes<<[12,10,h]
          types<<"comp_clt"

        elsif bd_width <= 60
          positions<<[bd_width/3,core_y]
          sizes<<[3,8,h]
          types<<"f_str"

          positions<<[(bd_width * 0.75)-3,core_y]
          sizes<<[9,10,h]
          types<<"comp_clt"

        else bd_width <= 72
          positions<<[15,0]
          sizes<<[3,8,h]
          types<<"f_str"

          positions<<[(bd_width-30)/2 + 30,core_y]
          sizes<<[12,10,h]
          types<<"comp_clt"
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

      zero=Geom::Point3d.new(0,0,0)
      scales=[
          host.gp.transformation.xscale,
          host.gp.transformation.yscale,
          host.gp.transformation.zscale
      ]

      for i in 0..positions.size-1

        for j in 0..positions[i].size-1
          positions[i][j] /= scales[j]
        end
        p=positions[i]
        s=sizes[i]
        t=types[i]
        p "p=#{p}, s=#{s}, t=#{t}"
        create_geometry("level2",p,s,t, Alignment::S,true)

      end
    end
  end

  class Decompose_FLBF < SpatialGenerator
    def initialize(host)
      @host=host
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

end
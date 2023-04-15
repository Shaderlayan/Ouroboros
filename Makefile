FXC := fxc
FXCFLAGS := /O3 /nologo /Iinclude

SHPKTOOL := tools/shpk.py

MKDIR_P := mkdir -p
RM_R := rm -r

IRIS_VS_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
IRIS_VS_FXCFLAGS := /DSHPK_IRIS /DSTAGE_VERTEX

IRIS_PS_Z_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
IRIS_PS_Z_FXCFLAGS := /DSHPK_IRIS /DSTAGE_PIXEL

IRIS_PS_G_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
IRIS_PS_G_FXCFLAGS := /DSHPK_IRIS /DSTAGE_PIXEL

IRIS_PS_COMPOSITE_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
IRIS_PS_COMPOSITE_FXCFLAGS := /DSHPK_IRIS /DSTAGE_PIXEL

SKIN_VS_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
SKIN_VS_FXCFLAGS := /DSHPK_SKIN /DSTAGE_VERTEX

SKIN_PS_Z_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
SKIN_PS_Z_FXCFLAGS := /DSHPK_SKIN /DSTAGE_PIXEL

SKIN_PS_G_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
SKIN_PS_G_FXCFLAGS := /DSHPK_SKIN /DSTAGE_PIXEL

SKIN_PS_COMPOSITE_DEPS := include/structs.hlsl include/resources.hlsl include/functions.hlsl
SKIN_PS_COMPOSITE_FXCFLAGS := /DSHPK_SKIN /DSTAGE_PIXEL

all: \
		build/iris.shpk \
		build/skin.shpk

# Shader Packages

build/iris.shpk: iris.shpk \
		build/iris/vs0.dxbc build/iris/vs5.dxbc \
		build/iris/vs1.dxbc build/iris/vs6.dxbc \
		build/iris/vs2.dxbc build/iris/vs7.dxbc \
		build/iris/vs3.dxbc build/iris/vs8.dxbc \
		build/iris/vs4.dxbc build/iris/vs9.dxbc \
		build/iris/ps0.dxbc build/iris/ps6.dxbc \
		build/iris/ps1.dxbc build/iris/ps7.dxbc \
		build/iris/ps2.dxbc build/iris/ps8.dxbc \
		build/iris/ps3.dxbc build/iris/ps9.dxbc \
		build/iris/ps4.dxbc build/iris/ps10.dxbc \
		build/iris/ps5.dxbc build/iris/ps11.dxbc
	$(SHPKTOOL) update $< $@ \
        vs0 build/iris/vs0.dxbc \
        vs1 build/iris/vs1.dxbc \
        vs2 build/iris/vs2.dxbc \
        vs3 build/iris/vs3.dxbc \
        vs4 build/iris/vs4.dxbc \
        vs5 build/iris/vs5.dxbc \
        vs6 build/iris/vs6.dxbc \
        vs7 build/iris/vs7.dxbc \
        vs8 build/iris/vs8.dxbc \
        vs9 build/iris/vs9.dxbc \
        ps0 build/iris/ps0.dxbc \
        ps1 build/iris/ps1.dxbc \
        ps2 build/iris/ps2.dxbc \
        ps3 build/iris/ps3.dxbc \
        ps4 build/iris/ps4.dxbc \
        ps5 build/iris/ps5.dxbc \
        ps6 build/iris/ps6.dxbc \
        ps7 build/iris/ps7.dxbc \
        ps8 build/iris/ps8.dxbc \
        ps9 build/iris/ps9.dxbc \
        ps10 build/iris/ps10.dxbc \
        ps11 build/iris/ps11.dxbc

build/skin.shpk: skin.shpk \
		build/skin/vs0.dxbc build/skin/vs3.dxbc \
		build/skin/vs1.dxbc build/skin/vs4.dxbc \
		build/skin/vs2.dxbc build/skin/vs5.dxbc \
		build/skin/vs6.dxbc build/skin/vs8.dxbc \
		build/skin/vs7.dxbc build/skin/vs9.dxbc \
		build/skin/ps0.dxbc build/skin/ps5.dxbc \
		build/skin/ps1.dxbc build/skin/ps6.dxbc \
		build/skin/ps2.dxbc build/skin/ps7.dxbc \
		build/skin/ps3.dxbc build/skin/ps8.dxbc \
		build/skin/ps4.dxbc build/skin/ps9.dxbc \
		build/skin/ps10.dxbc build/skin/ps14.dxbc \
		build/skin/ps11.dxbc build/skin/ps15.dxbc \
		build/skin/ps12.dxbc build/skin/ps16.dxbc \
		build/skin/ps13.dxbc build/skin/ps17.dxbc \
		build/skin/ps18.dxbc build/skin/ps20.dxbc \
		build/skin/ps19.dxbc build/skin/ps21.dxbc
	$(SHPKTOOL) update $< $@ \
		vs0 build/skin/vs0.dxbc \
		vs1 build/skin/vs1.dxbc \
		vs2 build/skin/vs2.dxbc \
		vs3 build/skin/vs3.dxbc \
		vs4 build/skin/vs4.dxbc \
		vs5 build/skin/vs5.dxbc \
		vs6 build/skin/vs6.dxbc \
		vs7 build/skin/vs7.dxbc \
		vs8 build/skin/vs8.dxbc \
		vs9 build/skin/vs9.dxbc \
		ps0 build/skin/ps0.dxbc \
		ps1 build/skin/ps1.dxbc \
		ps2 build/skin/ps2.dxbc \
		ps3 build/skin/ps3.dxbc \
		ps4 build/skin/ps4.dxbc \
		ps5 build/skin/ps5.dxbc \
		ps6 build/skin/ps6.dxbc \
		ps7 build/skin/ps7.dxbc \
		ps8 build/skin/ps8.dxbc \
		ps9 build/skin/ps9.dxbc \
		ps10 build/skin/ps10.dxbc \
		ps11 build/skin/ps11.dxbc \
		ps12 build/skin/ps12.dxbc \
		ps13 build/skin/ps13.dxbc \
		ps14 build/skin/ps14.dxbc \
		ps15 build/skin/ps15.dxbc \
		ps16 build/skin/ps16.dxbc \
		ps17 build/skin/ps17.dxbc \
		ps18 build/skin/ps18.dxbc \
		ps19 build/skin/ps19.dxbc \
		ps20 build/skin/ps20.dxbc \
		ps21 build/skin/ps21.dxbc

# Iris Vertex Shaders

build/iris/vs0.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_SHADOW0 /DPASS_Z $< /Fo $@

build/iris/vs1.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

build/iris/vs2.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/iris/vs3.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/iris/vs4.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

build/iris/vs5.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_SHADOW0 /DPASS_Z $< /Fo $@

build/iris/vs6.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

build/iris/vs7.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/iris/vs8.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/iris/vs9.dxbc: iris/vs.hlsl $(IRIS_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(IRIS_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

# Iris Pixel Shaders

build/iris/ps0.dxbc: iris/ps-z.hlsl $(IRIS_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_Z_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_SHADOW0 /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

build/iris/ps1.dxbc: iris/ps-g.hlsl $(IRIS_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_G_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/iris/ps2.dxbc: iris/ps-g.hlsl $(IRIS_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_G_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/iris/ps3.dxbc: iris/ps-composite.hlsl $(IRIS_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/iris/ps4.dxbc: iris/ps-composite.hlsl $(IRIS_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/iris/ps5.dxbc: iris/ps-z.hlsl $(IRIS_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_Z_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

build/iris/ps6.dxbc: iris/ps-z.hlsl $(IRIS_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_Z_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_SHADOW0 /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

build/iris/ps7.dxbc: iris/ps-g.hlsl $(IRIS_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_G_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/iris/ps8.dxbc: iris/ps-g.hlsl $(IRIS_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_G_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/iris/ps9.dxbc: iris/ps-composite.hlsl $(IRIS_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/iris/ps10.dxbc: iris/ps-composite.hlsl $(IRIS_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/iris/ps11.dxbc: iris/ps-z.hlsl $(IRIS_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(IRIS_PS_Z_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

# Skin Vertex Shaders

build/skin/vs0.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/skin/vs1.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/skin/vs2.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

build/skin/vs3.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_G $< /Fo $@

build/skin/vs4.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_COMPOSITE $< /Fo $@

build/skin/vs5.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_MAIN /DPASS_Z $< /Fo $@

build/skin/vs6.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_SHADOW0 /DPASS_Z $< /Fo $@

build/skin/vs7.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_RIGID /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

build/skin/vs8.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_SHADOW0 /DPASS_Z $< /Fo $@

build/skin/vs9.dxbc: skin/vs.hlsl $(SKIN_VS_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T vs_5_0 $(FXCFLAGS) $(SKIN_VS_FXCFLAGS) /DXFORM_SKIN /DSUBVIEW_CUBE0 /DPASS_Z $< /Fo $@

# Skin Pixel Shaders

build/skin/ps0.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_FACE /DPASS_G $< /Fo $@

build/skin/ps1.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_FACE /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/skin/ps2.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_FACE /DPASS_COMPOSITE $< /Fo $@

build/skin/ps3.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_FACE /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/skin/ps4.dxbc: skin/ps-z.hlsl $(SKIN_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_Z_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_FACE /DPART_BODY /DPART_BODY_HRO /DPASS_Z $< /Fo $@

build/skin/ps5.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_FACE /DPASS_G $< /Fo $@

build/skin/ps6.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_FACE /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/skin/ps7.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_FACE /DPASS_COMPOSITE $< /Fo $@

build/skin/ps8.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_FACE /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/skin/ps9.dxbc: skin/ps-z.hlsl $(SKIN_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_Z_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_FACE /DPART_BODY /DPART_BODY_HRO /DPASS_Z $< /Fo $@

build/skin/ps10.dxbc: skin/ps-z.hlsl $(SKIN_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_Z_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_SHADOW0 /DSUBVIEW_CUBE0 /DPART_FACE /DPART_BODY /DPART_BODY_HRO /DPASS_Z $< /Fo $@

build/skin/ps11.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_BODY /DPART_BODY_HRO /DPASS_G /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/skin/ps12.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_BODY /DPASS_COMPOSITE $< /Fo $@

build/skin/ps13.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_BODY /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/skin/ps14.dxbc: skin/ps-z.hlsl $(SKIN_PS_Z_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_Z_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_SHADOW0 /DSUBVIEW_CUBE0 /DPART_FACE /DPART_BODY /DPART_BODY_HRO /DPASS_Z $< /Fo $@

build/skin/ps15.dxbc: skin/ps-g.hlsl $(SKIN_PS_G_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_G_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_BODY /DPART_BODY_HRO /DPASS_G /DPASS_G_SEMITRANSPARENCY $< /Fo $@

build/skin/ps16.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_BODY /DPASS_COMPOSITE $< /Fo $@

build/skin/ps17.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_BODY /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/skin/ps18.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_BODY_HRO /DPASS_COMPOSITE $< /Fo $@

build/skin/ps19.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_OFF /DSUBVIEW_MAIN /DPART_BODY_HRO /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

build/skin/ps20.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_BODY_HRO /DPASS_COMPOSITE $< /Fo $@

build/skin/ps21.dxbc: skin/ps-composite.hlsl $(SKIN_PS_COMPOSITE_DEPS)
	@$(MKDIR_P) $(@D)
	$(FXC) /T ps_5_0 $(FXCFLAGS) $(SKIN_PS_COMPOSITE_FXCFLAGS) /DDITHERCLIP_ON /DSUBVIEW_MAIN /DPART_BODY_HRO /DPASS_COMPOSITE_SEMITRANSPARENCY $< /Fo $@

# Misc. & Phony Targets

clean:
	-$(RM_R) build/iris
	-$(RM_R) build/skin

mrproper: clean
	-$(RM_R) build

.PHONY: all clean mrproper

# Atramentum Luminis Authoring Manual

For optimal material authoring experience, it's strongly recommended to install [Material Development Kit](https://heliosphere.app/mod/bktfny69y57gf4y42bp4tn5z38), at a lower priority than Atramentum Luminis.

Please note that this manual expects the reader to have a certain level of knowledge about general texture editing, and knowledge about how to locate the wanted files in Penumbra.

It also assumes that the reader can use a texture editing program that fully preserves color information even in transparent pixels.

If you make mods that target Atramentum Luminis and/or write alternate versions or complements of this manual or parts of it, please make sure to specify the frameworks they are for, including version: Atramentum Luminis major version number changes if and only if some compatibility with previous versions is broken (in other words, 3.x is somewhat incompatible with 2.x, and 2.x is somewhat incompatible with 1.x – though it will take 271 more compatibility breaks to reach version 274.0 😉).

## Level 1: Textures-only

This level only requires editing textures to put information in some channels that are unused by the vanilla game.

The mods you can make will target the "Textures-only" skin and iris frameworks.

**Deprecated**: Creating new textures-only mods is not recommended, as the "Textures-only" frameworks are likely to be removed in the Atramentum Luminis Dawntrail update. It is instead recommended to also do material edits, as described in levels 2 and/or 3.

### Iris: Glow (Emissive)

To add glow information to irises, you have to edit the multi map (which has a filename usually ending in `_s.tex`).

The glow information is to be added to the multi map's alpha channel, in inverted form, that is:
- Where the alpha channel is "white" (so the texel is opaque), things will behave as in the vanilla game, with no glow ;
- Where the alpha channel is "black" (so the texel is transparent), the diffuse will be wholly turned into emissive, in other words the eye will glow at maximum intensity ;
- In-between alpha values can be used to locally adjust the intensity of the effect.

### Skin: Glow (Emissive)

To add glow information to skin (including nails, sclerae, Auri scales), you have to edit the diffuse map (which has a filename usually ending in `_d.tex`).

The glow information is to be added to the diffuse map's alpha channel, in inverted form (see above).

### Compatibility

The vanilla game ignores the aforementioned alpha channels. Therefore, using textures with edited alpha without Atramentum Luminis won't cause bugs or visual glitches, it will just give the same result as if the alpha edit was not done.

## Level 2: Textures and Materials

This level requires editing textures the same way as above, but also materials.

The mods you can make will target the "Textures and Materials" skin and iris frameworks.

For all of the sections below, you first have to select the wanted material in Penumbra's Advanced Editing window and go into the Material Constants section. Once you're done, don't forget to save your file and redraw yourself to make the changes permanent.

### Iris/Skin: Glow Adjustment

To globally adjust the iris or skin glow, set the **Emissive Conversion** constants.

Both constants must be set to 1 if you just want to have the same result as with the "Textures-only" frameworks.

### Hair: Glow (Emissive) and Glow Adjustment

To add glow information to hair, you have to edit the multi map. The glow information is to be added to the multi map's blue channel, in non-inverted form ("black" is no glow, "white" is full glow).

To globally adjust the hair glow, set the **Emissive Conversion** constants, as described above.

### Skin: Hair on Standard (non-Hrothgar) Body

To add hair information to skin that uses the standard body shader, set the **Enable Hair Influence** constant to Yes.

Then, add the hair influence information (just like the green channel for the Hrothgar shader) to the blue channel, and add the primary/secondary mix information (just like the blue channel for the Hrothgar shader) to the alpha channel.

The multi map's green channel will still be used as a specular map (instead of the hardcoded 20% value the Hrothgar shader uses).

### Skin: Auri Scale Iridescence

To add an iridescence effect to Auri scales like in the Hannish scale ointment mod, set the constants of the **Iridescence** section on a skin material.

Auri scales are detected depending on the red channel of the multi map: by default, values between 25% and 75% are considered scales.

- **Effect Strength** is the global iridescence effect multiplier ;
- **Scale Detection Range Center** shifts the scale detection range: for example (assuming other control values are 0), 0.5 means 25% to 75%, 0.3 means 5% to 55% ;
- **Scale Detection Range Tolerance** narrows or expands the scale detection range: for example (assuming other control values are 0), 0.25 means 25% to 75%, 0.35 means 15% to 85% ;
- **Scale Detection Range Fuzziness** sharpens or softens the ends of the scale detection range: for example (assuming other control values are 0), 0.05 means that the effect gradually rolls off from 30% to 20%, 0 means that it's all-or-nothing above and below 25% ;
- **Normal Z Bias** attenuates the effect by applying a bias to the normals: 0 is equivalent to HSO's "Vibrant" options, 0.5 is equivalent to HSO's "Normal" options, 1 is equivalent to HSO's "Faint" options ;
- **Chroma** is the maximum chroma radius to use: 0 will make the effect gray, 50 will be equivalent to HSO ;
- **Hue Shift** is the hue angle shift in degrees: 0 gives a reddish hue to scales that face towards the right of the screen, positive values rotate the effect counterclockwise ;
- **Hue Multiplier** is the hue angle multiplier (it will be rounded to the nearest integer).

The effect is compatible with most scale overlays with the three control values left at 0, and should be compatible with all of them by tweaking these values.

Note: all the builds of Hannish scale ointment since 2.0 are actually just special builds of Atramentum Luminis's "Textures-only" skin framework, with this constant forced to 1, 0, 0, 0, 0|0.5|1, 50, 0|90|180|-90, 1|-1|3.

### Skin: Asymmetry Adapter

If you want to use an asymmetric texture with a symmetric model, or a symmetric texture with an asymmetric model, set the **Asymmetry Adapter** constant.

- If your texture matches your model, the constant must be set to *None* ;
- If your texture is asymmetric and your model is symmetric, the constant must be set to *Sym. model, asym. textures* ;
- If your texture is symmetric and your model is asymmetric, the constant must be set to *Asym. model, sym. textures*.

Please note that the remapping functions used are very simple (namely, `uAsym = (1±uSym)/2`, `tAsym = ±tSym`, u and t denoting respectively the horizontal texture coordinate and the surface tangent vector). It happens that the Bibo+ and The Body SE UV layouts and surface geometries have a relationship with the vanilla/Gen2 ones that's mostly accurately modeled by these equations, but it's not perfect (especially for NSFW). If you want an asymmetric texture that completely works on vanilla/Gen2 models, you'll have to work with a properly "unfolded" vanilla/Gen2 texture.

Also, due to Gen3 not having a straightforward enough relationship with vanilla/Gen2, the asymmetry adapter will likely never work with it (contributions are welcome though 😉).

The left half of the textures will be applied to the right half of the body/face/tail/…, and the right half of the textures will be applied to the left half of the body/face/tail/… (if you set the camera right in front of your character, the left of the texture will be to the left of the screen).

*TL;DR*: The asymmetry adapter "unfolds" a symmetric UV layout. It happens to mostly work with Bibo+ and The Body SE because they're similar to "unfolded" vanilla/Gen2. It doesn't work at all with Gen3 because it's not.

### Iris: Asymmetry Adapter

If you want to use an asymmetric texture with a symmetric model, a symmetric texture with an asymmetric model, or an asymmetric catchlight map, set the **Asymmetry Adapter** constants.

- **Asymmetry Adapter** works in the same way as for the skin ;
- **Catchlight Asymmetry Adapter** must be *Symmetric catchlight map* if your catchlight map is symmetric, *Asymmetric catchlight map* if it's asymmetric.

The left half of the textures will be applied to the right eye, and the right half of the textures will be applied to the left eye (if you set the camera right in front of your character, the left of the texture will be to the left of the screen).

Please note that the catchlight map's UVs have nothing to do with the vertex UVs: instead, they are calculated using the normal vector. It is therefore impossible to change the catchlight map's UV layout using something else than a shader package without adverse effects.

### Hair/Iris/Skin: 1.x/2.x-like Bloom Effect

The overdone bloom effect that was found in Atramentum Luminis 1.x and 2.x was due to it being calculated using a wrong formula (in some way, it's a bug that's been fixed in 3.0).

Yet, if you liked it, it's still available, and can be configured by setting the **Legacy Bloom** constants.

### Compatibility

The vanilla game ignores the new parameters, and the "Textures-only" frameworks take into account some of the parameters and ignore the others (yet, if you do any material edits, it's recommended to work only with the "Textures and Materials" frameworks). Therefore, using edited materials without Atramentum Luminis will give the same result as if the parameters were not defined. Using edited materials with "Textures-only" frameworks will give results that may be stronger or weaker than indended.

## Level 3: More Textures and Materials

This level requires editing textures and materials further than above.

The mods you can make will also target the "Textures and Materials" skin and iris frameworks.

Please note that this level changes how some things are interpreted in such a way that, just as with level 2, only enabling it without proper configuration can nullify some of the effects with no benefit.

### Skin/Hair/Iris: Switching to level 3

In the Shader section, set **Atramentum Luminis Semantics** to *Level 3*.

This will automatically add new maps as required, set to a default that does not enable any new effects. You then have to change the paths for maps you want to actually use.

There is no standard path for these new maps, but I suggest following the convention of the existing maps of your material, with a `_d` suffix for the diffuse, `_e` suffix for the emissive and `_x` for the effect mask.

### Skin: Using the emissive map

The red, green and blue channels of the emissive map are actual color data.

The alpha channel of the emissive map is interpreted as "how much does this map override the emissive that level 2 would have generated".

The glow adjustment parameter still applies to the emissive map.

### Hair/Iris: Using the diffuse and emissive maps

The red, green and blue channels of the diffuse and emissive maps are actual color data.

The alpha channel of the diffuse and emissive maps is interpreted as "how much does this map override the diffuse/emissive that level 2 would have generated".

The multi map's alpha channel and glow adjustment parameter still apply to the diffuse map, and the glow adjustment parameter also still applies to the emissive map.

### Iris: Using the effect mask

The red, green and blue channels are currently unused. They should be left at zero (i. e. the texture should be only gradients of black to transparent).

The alpha channel is used to locally control the bloom effect (instead of the inverted multi map's alpha channel in level 2): where the alpha channel is "black" (so the texel is transparent), the bloom effect will be disabled, where the alpha channel is "white" (so the texel is opaque), the bloom effect will be at full power. The glow adjusment and bloom effect parameters still apply.

### Skin: Using the effect mask

The red channel is used to control the iridescence effect (instead of a function of the multi map's red channel as in level 2): where the red channel is black, the iridescence effect will be disabled, where the red channel is red, the iridescence effect will be at full power. Consequently, the scale detection control values (second, third and fourth) of the iridescence parameter are ignored. The other values still apply.

The green channel is used to control the perma-wetness effect (BETA): where the green channel is black, the skin will be normally dry or wet depending on the environment, where the green channel is green, the skin will be permanently wet.

The blue channel is used to control the metallic finish effect (BETA): where the blue channel is black, the effect will be disabled, when the blue channel is blue, the skin will get a metallic finish, which can be used for example for visible implants.

The alpha channel is used to locally control the bloom effect as in the iris effect mask. The glow adjustment and bloom effect parameters still apply.

You can use the following JSON file in PNG Mapper to automatically generate an effect mask with scale iridescence out of a multi, assuming scale detection control values are all zero (otherwise, the script can be tweaked accordingly):

```json
{
  "inputs": [ "in_m" ],
  "outputs": [ "out_x" ],
  "mapping": "out_x.r = 1.0 - smoothstep(\n  0.2, 0.3, Math.abs(in_m.r - 0.5));\n\nout_x.g = 0.0;\nout_x.b = 0.0;\nout_x.a = 1.0;"
}
```

### Hair: Iridescence and Using the effect mask

The effect mask for hair works exactly like the one for skin.

Hair iridescence is only available at level 3 and works the same way as level 3 skin iridescence (the mask has to be explicit and the 2nd, 3rd and 4th values of the material parameter are ignored).

### Compatibility

The vanilla game and the "Textures-only" frameworks ignore the new shader key and samplers. Therefore, using materials with level 3 edits without Atramentum Luminis or with a "Textures-only" framework will give the same results as if the shader key and samplers were not defined.

### Tips

The game provides a few solid color textures at the following paths (figuring out which texture has which color is left as an exercise to the reader 😉):

- `chara/common/texture/transparent.tex` ;
- `chara/common/texture/black.tex` ;
- `chara/common/texture/white.tex` ;
- `chara/common/texture/red.tex` ;
- `chara/common/texture/green.tex` ;
- `chara/common/texture/blue.tex` ;
- `chara/common/texture/null_normal.tex` ;
- `chara/common/texture/skin_m.tex`.

While all of the samplers (and associated textures) are mandatory for a level 3 material, if you don't need one of them or want to set what it controls to a uniform value, you can use these textures instead of making your own.

#ifndef IRI_FACTOR
#define IRI_FACTOR g_ScaleIridescence1.x
#endif

#ifndef IRI_Z_BIAS
#define IRI_Z_BIAS max(0.0, g_ScaleIridescence2.x)
#endif

#ifndef IRI_RHO
#define IRI_RHO g_ScaleIridescence2.y
#endif

#ifndef IRI_THETA_XPOS
#define IRI_THETA_XPOS g_ScaleIridescence2.z
#endif

#ifndef IRI_THETA_SCALE
#define IRI_THETA_SCALE g_ScaleIridescence2.w
#endif

#ifndef IRI_THETA_SKEW
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T) || defined(SHPK_CHARACTERGLASS)
#define IRI_THETA_SKEW g_ScaleIridescence1.y
#else
#define IRI_THETA_SKEW 0
#endif
#endif

float iridescenceFromSkinInfluence(const float skinInfluence)
{
    return 1.0 - smoothstep(
        0.2 + g_ScaleIridescence1.z - g_ScaleIridescence1.w,
        0.3 + g_ScaleIridescence1.z + g_ScaleIridescence1.w,
        abs(skinInfluence - (0.5 + g_ScaleIridescence1.y))
    );
}

struct IridescenceData
{
    bool complete;
    float factor;
    float3 colorBase;

    float3 color(const float lumaFactor)
    {
#ifdef IRI_COLORSPACE_LAB
        return lab2rgb(colorBase * float3(50.0 * lumaFactor, 1.0, 1.0) + float3(50.0, 0.0, 0.0));
#else
        return oklab2rgb(colorBase * float3(0.5 * lumaFactor, 0.003, 0.003) + float3(0.5, 0.0, 0.0));
#endif
    }
};

IridescenceData calculateIridescenceData(const float localFactor, float3 normal)
{
    IridescenceData iri;
    iri.colorBase = 0.0;

    iri.factor = IRI_FACTOR;
    if (iri.factor <= 0.0) {
        iri.complete = false;
        return iri;
    }
    iri.factor = saturate(iri.factor * localFactor);
    if (0.0 == iri.factor) {
        iri.complete = false;
        return iri;
    }
    normal.z += IRI_Z_BIAS;
    normal = normalize(normal);
    const float distanceFromCenter = length(normal.xy);

    float s, c;
    sincos(atan2(normal.y, normal.x) * round(IRI_THETA_SCALE) + radians(IRI_THETA_XPOS) + distanceFromCenter * IRI_THETA_SKEW, s, c);

    const float rho = distanceFromCenter * IRI_RHO;
    iri.colorBase = float3(normal.z, c * rho, s * rho);

    iri.complete = true;
    return iri;
}

float3 applyIridescence(const float3 diffuse, const float localIridescence, const float3 normal)
{
    const IridescenceData iri = calculateIridescenceData(localIridescence, normal);
    if (!iri.complete) {
        return diffuse;
    }

    const float3 dark = screen(diffuse, lerp(0.0, iri.color(-1.0), iri.factor));
    const float3 light = diffuse * lerp(1.0, iri.color(1.0), iri.factor);

    return lerp(dark, light, smoothstep(0.45, 0.55, dot(diffuse, float3(0.2126, 0.7152, 0.0722))));
}

float4 applyIridescenceGlass(const float3 diffuse, const float alpha, const float localIridescence, const float3 normal)
{
    const IridescenceData iri = calculateIridescenceData(localIridescence, normal);
    if (!iri.complete) {
        return float4(diffuse, alpha);
    }

    const float3 dark = screen(diffuse, lerp(0.0, iri.color(-1.0), iri.factor));
    const float3 light = diffuse * lerp(1.0, iri.color(1.0), iri.factor);
    const float3 color = lerp(dark, light, smoothstep(0.45, 0.55, dot(diffuse, float3(0.2126, 0.7152, 0.0722))));

    const float midAlpha = (1.0 - alpha) * iri.factor * (1.0 - iri.colorBase.x);
    const float3 midColor = iri.color(0.0);

    return float4((color * alpha + midColor * midAlpha) / (alpha + midAlpha), alpha + midAlpha);
}

float3 applyIridescenceSq(const float3 diffuseSq, const float localIridescence, float3 normal)
{
    const float3 iridescent = applyIridescence(sqrt(max(0, diffuseSq)), localIridescence, normal);
    return iridescent * iridescent;
}

float4 applyIridescenceGlassSq(const float3 diffuseSq, const float alpha, const float localIridescence, float3 normal)
{
    const float4 iridescent = applyIridescenceGlass(sqrt(max(0, diffuseSq)), alpha, localIridescence, normal);
    return float4(iridescent.xyz * iridescent.xyz, iridescent.w);
}

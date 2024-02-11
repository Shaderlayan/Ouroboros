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
#if defined(ALUM_LEVEL_3) || defined(ALUM_LEVEL_T)
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

float3 applyIridescence(const float3 diffuse, const float localIridescence, float3 normal)
{
    float factor = IRI_FACTOR;
    if (factor <= 0.0) {
        return diffuse;
    }
    factor = saturate(factor * localIridescence);
    if (0.0 == factor) {
        return diffuse;
    }
    normal.z += IRI_Z_BIAS;
    normal = normalize(normal);
    const float distanceFromCenter = length(normal.xy);

    float s, c;
    sincos(atan2(normal.y, normal.x) * round(IRI_THETA_SCALE) + radians(IRI_THETA_XPOS) + distanceFromCenter * IRI_THETA_SKEW, s, c);

    const float rho = distanceFromCenter * IRI_RHO;
    const float3 adjusted = float3(normal.z, c * rho, s * rho);

#ifdef IRI_COLORSPACE_LAB
    const float3 light = lab2rgb(adjusted * float3(50.0, 1.0, 1.0) + float3(50.0, 0.0, 0.0));
    const float3 dark = lab2rgb(adjusted * float3(-50.0, 1.0, 1.0) + float3(50.0, 0.0, 0.0));
#else
    const float3 light = oklab2rgb(adjusted * float3(0.5, 0.003, 0.003) + float3(0.5, 0.0, 0.0));
    const float3 dark = oklab2rgb(adjusted * float3(-0.5, 0.003, 0.003) + float3(0.5, 0.0, 0.0));
#endif

    return lerp(
        screen(diffuse, lerp(0.0, dark, factor)),
        diffuse * lerp(1.0, light, factor),
        smoothstep(0.45, 0.55, dot(diffuse, float3(0.2126, 0.7152, 0.0722)))
    );
}

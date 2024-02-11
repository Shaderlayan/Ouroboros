#ifdef VARIANT_WORRYASS

// This is a bitmap of a certain image that is a meme in certain circles.
// If you know, you know.

static const uint Worryass[] = {
    0x000ff8,
    0x0014a4,
    0x0026b6,
    0x00431a,
    0x008001,
    0x008005,
    0x008001,
    0x018002,
    0x038ffc,
    0x049004,
    0x09a00c,
    0x13200a,
    0x23200a,
    0x429809,
    0x42c42d,
    0x823815,
    0x82000d,
    0x82000a,
    0x810004,
    0x810004,
    0x808004,
    0x816004,
    0x4e5e04,
    0x3ffffc,
};

float4 worryass(float2 texCoord)
{
#ifdef PASS_COMPOSITE
    const float w = 0;
#endif
#ifdef PASS_COMPOSITE_SEMITRANSPARENCY
    const float w = 1;
#endif
    const float2 uv = frac(texCoord);
    const float2 waUV = (uv * 48) - 12;
    if (all(abs(waUV - 12) < 12)) {
        const uint2 waCoords = (uint2)trunc(waUV);
        const uint waRow = Worryass[waCoords.y];
        if ((waRow & (1 << (23 - waCoords.x))) != 0) {
            return float4(116.0/255.0, 96.0/255.0, 29.0/255.0, w);
        }
    }
    if (length(uv - 0.5) >= 0.4) {
        return float4(195.0/255.0, 148.0/255.0, 39.0/255.0, lerp(w, 1, 0.5));
    }
    return float4(235.0/255.0, 200.0/255.0, 89.0/255.0, w);
}

#endif

#include "Autolight.cginc"
#include "UnityLightingCommon.cginc"

fixed4 _Size; //h,w, rand h, rand w
fixed _HeightOffset;
fixed _RandomHeightOffset;

fixed _SpecPower;
fixed _Translucency;

sampler2D _WindDistortionMap;
float4 _WindDistortionMap_ST;
float _WindStrength;
fixed3 _WindFrequency;

struct v2g
{
    float4 pos : SV_POSITION;
    float3 norm : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct g2f
{
    float4 pos : SV_POSITION;
    float3 worldNorm : NORMAL;
    unityShadowCoord4 _ShadowCoord : TEXCOORD1;
    float2 uv : TEXCOORD0;
};

float random(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

[maxvertexcount(4)]
void geomPoint(point v2g i, inout TriangleStream<g2f> triStream)
{
    float rand = random(i.pos);

    float4 root = i.pos;
    float3 rootWorld = mul(unity_ObjectToWorld, root);

    g2f v[4];

    // Sample the wind distortion map, and construct a normalized vector of its direction.
    float2 windUV = rootWorld.xz * _WindDistortionMap_ST.xy + _WindFrequency.xy * _Time.y;
    float2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).xy * 2 - 1) * _WindStrength;
    float3 wind = float3(windSample.r, 0, windSample.g);

    root.xyz += wind * _WindFrequency.z;
    float3 grassDirection = normalize(fixed3(0, 1, 0) + wind);

    //Use camera forward instead view dir
    fixed3 viewDir = UNITY_MATRIX_IT_MV[2].xyz;


    fixed4 left = float4(normalize(cross(viewDir, grassDirection).xyz), 0);

    fixed heigth = _Size.x + _Size.z * rand;
    fixed width = _Size.y + _Size.w * rand;
    fixed heigthOffset = _HeightOffset + _RandomHeightOffset*rand;
    fixed4 grassTop = root + fixed4(grassDirection * (heigth + heigthOffset), 0);
    fixed4 grassBottom = root + fixed4(grassDirection * heigthOffset, 0);

    fixed3 norm = normalize(cross(grassTop - root, left));

    half3 worldNormal = UnityObjectToWorldNormal(norm);

    v[0].pos = UnityObjectToClipPos(grassBottom);
    v[0].worldNorm = worldNormal;

    v[1].pos = UnityObjectToClipPos(grassBottom + left * width);
    v[1].worldNorm = worldNormal;

    v[2].pos = UnityObjectToClipPos(grassTop);
    v[2].worldNorm = worldNormal;

    v[3].pos = UnityObjectToClipPos(grassTop + left * width);
    v[3].worldNorm = worldNormal;

    #if SIMPLE_SHADOW
    v[0]._ShadowCoord = ComputeScreenPos(v[0].pos);
    v[1]._ShadowCoord = ComputeScreenPos(v[1].pos);
    v[2]._ShadowCoord = ComputeScreenPos(v[0].pos);
    v[3]._ShadowCoord = ComputeScreenPos(v[1].pos);
    #else
    v[0]._ShadowCoord = ComputeScreenPos(v[0].pos);
    v[1]._ShadowCoord = ComputeScreenPos(v[1].pos);
    v[2]._ShadowCoord = ComputeScreenPos(v[2].pos);
    v[3]._ShadowCoord = ComputeScreenPos(v[3].pos);
    #endif

    v[0].uv = float2(0, 0);
    v[1].uv = float2(1, 0);
    v[2].uv = float2(0, 1);
    v[3].uv = float2(1, 1);

    triStream.Append(v[0]);
    triStream.Append(v[2]);
    triStream.Append(v[1]);
    triStream.Append(v[3]);
    triStream.Append(v[2]);
    triStream.Append(v[1]);
}

[maxvertexcount(4)]
void geomPoints(point v2g i[1], inout TriangleStream<g2f> triStream)
{
    geomPoint(i[0], triStream);
}

[maxvertexcount(4)]
void geomTriangle(triangle v2g i[3], inout TriangleStream<g2f> triStream)
{
    geomPoint(i[0], triStream);
}

fixed3 sampleLight(g2f i)
{
    #if !UNITY_PASS_SHADOWCASTER
    fixed lightDot = dot(i.worldNorm, normalize(_WorldSpaceLightPos0.xyz));
    fixed3 diffuseLight = saturate(saturate(lightDot) + _Translucency) * _LightColor0;
    float shadow = SHADOW_ATTENUATION(i);
    fixed3 ambient = ShadeSH9(half4(i.worldNorm, 1));
    return diffuseLight * shadow + ambient;
    #else
    return 0;
    #endif
}

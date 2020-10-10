#include "Autolight.cginc"
#include "UnityLightingCommon.cginc"

fixed4 _RandomPosition;
fixed _Width;
fixed _Height;
fixed _HeightOffset;

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
    float2 uv : TEXCOORD0;
    float4 tangent : TANGENT;
};

struct g2f
{
    float4 worldPos : SV_POSITION;
    float3 worldNorm : NORMAL;
    float2 uv : TEXCOORD0;
    unityShadowCoord4 _ShadowCoord : TEXCOORD1;
};

float random(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

[maxvertexcount(4)]
void geomPoint(point v2g i, inout TriangleStream<g2f> triStream)
{
    float rand = random(i.pos);
    fixed3 binormal = cross(i.norm, i.tangent);
    fixed3 offset = rand * _RandomPosition * (i.tangent.xyz + i.norm + binormal);

    float4 root = i.pos + fixed4(offset, 0);
    float3 rootWorld = mul(unity_ObjectToWorld, root);

    g2f v[4];

    // Sample the wind distortion map, and construct a normalized vector of its direction.
    float2 windUV = rootWorld.xz * _WindDistortionMap_ST.xy + _WindFrequency.xy * _Time.y;
    float2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).xy * 2 - 1) * _WindStrength;
    float3 wind = float3(windSample.r, 0, windSample.g);

    root.xyz += wind * offset * _WindFrequency.z;
    float3 grassDirection = normalize(fixed3(0, 1, 0) + wind);

    //Use camera forward instead view dir
    fixed3 viewDir = UNITY_MATRIX_IT_MV[2].xyz;

    fixed4 left = float4(normalize(cross(viewDir, grassDirection).xyz), 0);

    fixed4 grassTop = root + fixed4(grassDirection * (_Height + _HeightOffset), 0);
    fixed4 grassBottom = root + fixed4(grassDirection * _HeightOffset, 0);

    fixed3 norm = normalize(cross(grassTop - root, left));

    half3 worldNormal = UnityObjectToWorldNormal(norm);

    v[0].worldPos = UnityObjectToClipPos(grassBottom);
    v[0].uv = float2(0, 0);
    v[0].worldNorm = worldNormal;
    v[0]._ShadowCoord = ComputeScreenPos(v[0].worldPos);

    v[1].worldPos = UnityObjectToClipPos(grassBottom + left * _Width);
    v[1].uv = float2(1, 0);
    v[1].worldNorm = worldNormal;
    v[1]._ShadowCoord = ComputeScreenPos(v[1].worldPos);

    v[2].worldPos = UnityObjectToClipPos(grassTop);
    v[2].uv = float2(0, 1);
    v[2].worldNorm = worldNormal;
    v[2]._ShadowCoord = ComputeScreenPos(v[0].worldPos);

    v[3].worldPos = UnityObjectToClipPos(grassTop + left * _Width);
    v[3].uv = float2(1, 1);
    v[3].worldNorm = worldNormal;
    v[3]._ShadowCoord = ComputeScreenPos(v[1].worldPos);

    triStream.Append(v[0]);
    triStream.Append(v[2]);
    triStream.Append(v[1]);
    triStream.Append(v[3]);
    triStream.Append(v[2]);
    triStream.Append(v[1]);
}

[maxvertexcount(4)]
void geomTriangle(triangle v2g i[3], inout TriangleStream<g2f> triStream)
{
    geomPoint(i[0], triStream);
}

fixed3 sampleLight(g2f i)
{
    fixed lightDot = dot(i.worldPos, UnityWorldSpaceLightDir(i.worldNorm));
    fixed3 diffuseLight = saturate(saturate(lightDot) + _Translucency) * _LightColor0;

    float shadow = SHADOW_ATTENUATION(i);
    fixed3 ambient = ShadeSH9(half4(i.worldNorm, 1));
    return diffuseLight * shadow + ambient;
}

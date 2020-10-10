Shader "Grass/TessellatedGrass"
{
    Properties
    {
        _Color1("Color 1", Color) =(1,1,1,1)
        _Color2("Color 2", Color) = (0,0,0,0)
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", float) = 1
        _Height("Height", float) = 3
        _Width("Width", float) = 0.05
        _RandomPosition("Random Position", vector) = (0, 0, 0, 0)
        _Translucency("Translucency", float) = 0.5
        _HeightOffset("Height Offset", float) = 0
        [Header(Wind)]
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindStrength("Wind Strength", float) = 1
        _WindFrequency("Wind Frequency", vector) = (0.05, 0.05, 0, 0)
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
                "LightMode" = "ForwardBase"
                "IgnoreProjector" = "True"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Autolight.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Tessellation.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geom
            #pragma multi_compile_fwdbase

            #pragma target 4.6

            fixed4 _Color1;
            fixed4 _Color2;
            fixed _SpecPower;
            fixed _Width;
            fixed _Translucency;
            fixed _Height;
            fixed _HeightOffset;
            fixed4 _RandomPosition;

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
                float4 pos : SV_POSITION;
                float3 worldNorm : NORMAL;
                float2 uv : TEXCOORD0;
                unityShadowCoord4 _ShadowCoord : TEXCOORD1;
            };

            float random(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            void generateMesh(point v2g i, inout TriangleStream<g2f> triStream)
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
                fixed3 viewDir = UNITY_MATRIX_IT_MV[2].xyz; //WorldSpaceViewDir(root);

                fixed4 left = float4(normalize(cross(viewDir, grassDirection).xyz), 0);

                fixed4 grassTop = root + fixed4(grassDirection * (_Height + _HeightOffset), 0);
                fixed4 grassBottom = root + fixed4(grassDirection * _HeightOffset, 0);

                fixed3 norm = normalize(cross(grassTop - root, left));

                half3 worldNormal = UnityObjectToWorldNormal(norm);

                v[0].pos = UnityObjectToClipPos(grassBottom);
                v[0].uv = float2(0, 0);
                v[0].worldNorm = worldNormal;
                v[0]._ShadowCoord = ComputeScreenPos(v[0].pos);

                v[1].pos = UnityObjectToClipPos(grassBottom + left * _Width);
                v[1].uv = float2(1, 0);
                v[1].worldNorm = worldNormal;
                v[1]._ShadowCoord = ComputeScreenPos(v[1].pos);

                v[2].pos = UnityObjectToClipPos(grassTop);
                v[2].uv = float2(0, 1);
                v[2].worldNorm = worldNormal;
                v[2]._ShadowCoord = ComputeScreenPos(v[0].pos);

                v[3].pos = UnityObjectToClipPos(grassTop + left * _Width);
                v[3].uv = float2(1, 1);
                v[3].worldNorm = worldNormal;
                v[3]._ShadowCoord = ComputeScreenPos(v[1].pos);

                triStream.Append(v[0]);
                triStream.Append(v[2]);
                triStream.Append(v[1]);
                triStream.Append(v[3]);
                triStream.Append(v[2]);
                triStream.Append(v[1]);
            }

            [maxvertexcount(4)]
            void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream)
            {
                generateMesh(i[0], triStream);
            }

            half4 frag(g2f i) : COLOR
            {
                fixed4 color = lerp(_Color1, _Color2, i.uv.y).xyzw;

                //diffuse
                fixed lightDot = dot(i.worldNorm, UnityWorldSpaceLightDir(i.pos));
                fixed3 diffuseLight = saturate(saturate(lightDot) + _Translucency) * _LightColor0;

                float shadow = SHADOW_ATTENUATION(i);
                fixed3 ambient = ShadeSH9(half4(i.worldNorm, 1));
                fixed3 light = diffuseLight * shadow + ambient;

                color.rgb *= light;
                return color;
            }
            ENDCG

        }
    }
}
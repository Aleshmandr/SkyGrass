﻿Shader "Grass/GrassGround"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FlakesNormTex ("Falkes Normal", 2D) = "white" {}
        _Color1("Color 1", Color) =(1,1,1,1)
        _Color2("Color 2", Color) =(1,1,1,1)
        _Power("Power", float) = 1

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
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
                "IgnoreProjector" = "True"
            }

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            float _Power;
            float _Thresh;
            fixed3 _Color1;
            fixed4 _Color2;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            sampler2D _FlakesNormTex;
            fixed4 _FlakesNormTex_ST;

            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;
            float _WindStrength;
            fixed3 _WindFrequency;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 worldPos : NORMAL;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;

                half3 tspace0 : TEXCOORD2; // tangent.x, bitangent.x, normal.x
                half3 tspace1 : TEXCOORD3; // tangent.y, bitangent.y, normal.y
                half3 tspace2 : TEXCOORD4; // tangent.z, bitangent.z, normal.z
                fixed2 wind : TEXCOORD6; // tangent.z, bitangent.z, normal.z
                SHADOW_COORDS(5) // put shadows data into TEXCOORD5
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                float2 windUV =   o.pos * _WindDistortionMap_ST.xy + _WindFrequency.xy * _Time.y;
                float2 windSample = (tex2Dlod(_WindDistortionMap, float4(windUV, 0, 0)).xy * 2 - 1) * _WindStrength;
                o.wind = windSample.rg;

                o.uv0 = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.texcoord, _FlakesNormTex);// + o.wind;

                half3 wNormal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // compute bitangent from cross product of normal and tangent
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
                // output the tangent space matrix
                o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
                TRANSFER_SHADOW(o)
                return o;
            }

            half4 frag(v2f i) : COLOR
            {
                fixed4 color = tex2D(_MainTex, i.uv0);
                color.rgb *= _Color1;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // sample the normal map, and decode from the Unity encoding
                half3 tnormal = UnpackNormal(tex2D(_FlakesNormTex, i.uv1) + i.wind.xyyy);
                // transform normal from tangent to world space
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);
                //worldNormal.xz+=;


                //return color +//saturate(abs((tnormal.x) + abs(tnormal.y))
                float3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
                fixed lightDot = dot(float3(i.tspace0.z, i.tspace1.z, i.tspace2.z), lightDir);
                fixed3 diffuseLight = saturate(lightDot) * _LightColor0;
                float shadow = SHADOW_ATTENUATION(i);
                fixed3 ambient = ShadeSH9(half4(worldNormal, 1));
                float3 light = diffuseLight * shadow + ambient;

                float3 lightReflectDirection = reflect(lightDir, worldNormal);
                float lightSeeDirection = pow(0.5 * (1 + dot(lightReflectDirection, viewDirection)), _Power);

                //return  fixed4(lightSeeDirection.xxx, 1);
                color.rgb += _Color2.rgb * lightSeeDirection * _Color2.a;
                color.rgb *= light;

                return color;
            }
            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    Fallback Off
}
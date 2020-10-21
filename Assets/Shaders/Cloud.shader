Shader "Clouds/Cloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", float) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_nicest

            #include "UnityCG.cginc"
            #define MAX_STEPS 100
            #define RAY_MAX_DIST 10000
            #define RAY_HIT_THRESH 0.01

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 pos : TEXCOORD1;
                float3 ro : TEXCOORD2;
            };

            float _Radius;

            float distFunc(float3 p)
            {
                return length(p) - _Radius;
            }

            float raymarch(float3 rayOrigin, float3 rayDirection)
            {
                //return distFunc(rayOrigin);
                float dist = 0;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = rayOrigin + rayDirection * dist;
                    float ds = distFunc(p);
                    dist += ds;
                    if (ds < RAY_HIT_THRESH || dist > RAY_MAX_DIST)
                    {
                        break;
                    }
                }
                return dist;
            }

            float raymarch2(float3 rayOrigin, float3 rayDirection)
            {
                //return distFunc(rayOrigin);
                float dist = 0;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = rayOrigin + rayDirection * dist;
                    float ds = distFunc(p);
                    dist += ds;
                    if (ds < RAY_HIT_THRESH || dist > RAY_MAX_DIST)
                    {
                        return ds;
                    }
                }
                return RAY_MAX_DIST;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex;
                o.uv = v.uv;

                o.ro = mul(unity_WorldToObject, fixed4(_WorldSpaceCameraPos, 1));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 rd = normalize(i.pos - i.ro);
                float rm = raymarch(i.ro, rd);
                return fixed4(rm.xxx / 10, 1);
            }
            ENDCG
        }
    }
}
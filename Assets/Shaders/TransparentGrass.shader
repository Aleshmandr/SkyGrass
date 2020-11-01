Shader "Grass/TransparentGrass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1("Color 1", Color) =(1,1,1,1)
        _Color2("Color 2", Color) =(1,1,1,1)
        _Size("Size (h, w, rand h, rand w)", vector) = (0.2, 0.05, 0, 0)
        _Translucency("Translucency", float) = 0.5
        _HeightOffset("Height Offset", float) = 0
        _RandomHeightOffset("Random Height Offset", float) = 0
        [Header(Wind)]
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindStrength("Wind Strength", float) = 1
        _WindFrequency("Wind Frequency", vector) = (0.05, 0.05, 0, 0)
        _Cutoff("Cutoff", float) = 0
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "Queue" = "AlphaTest"
                "RenderType" = "Transparent"
                "LightMode" = "ForwardBase"
                "IgnoreProjector" = "True"
            }

            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #define SIMPLE_SHADOW 0
            #include "UnityCG.cginc"
            #include "GeometryGrass.cginc"
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geomPoints
            #pragma multi_compile_fwdbase

            fixed4 _Color1;
            fixed4 _Color2;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            float _Cutoff;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            vertexInput vert(vertexInput v)
            {
                return v;
            }

            half4 frag(g2f i) : COLOR
            {
                fixed4 color = tex2D(_MainTex, i.uv) * lerp(_Color1, _Color2, i.uv.y);
                clip(color.a - _Cutoff);
                color.rgb *= sampleLight(i);

                return color;
            }
            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "GeometryGrass.cginc"
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geomPoints
            #pragma multi_compile_shadowcaster

            fixed4 _Color1;
            fixed4 _Color2;
            float _Cutoff;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            vertexInput vert(vertexInput v)
            {
                return v;
            }

            float4 frag(g2f i) : SV_Target
            {
                fixed a = tex2D(_MainTex, i.uv).a * lerp(_Color1.a, _Color2.a, i.uv.y);
                clip(a - _Cutoff);
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
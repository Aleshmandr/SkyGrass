﻿Shader "Grass/TransparentTessellatedGrass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) =(1,1,1,1)
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
                "Queue" = "AlphaTest"
                "RenderType" = "Transparent"
                "LightMode" = "ForwardBase"
                "IgnoreProjector" = "True"
            }

            ZWrite Off

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #define SIMPLE_SHADOW 1
            #include "UnityCG.cginc"
            #include "GeometryGrass.cginc"
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geomPoints
            #pragma multi_compile_fwdbase

            fixed4 _Color;
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

            half4 frag(g2f i) : COLOR
            {
                fixed4 color = tex2D(_MainTex, i.uv) * _Color;
                color.rgb *= sampleLight(i);
                return color;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
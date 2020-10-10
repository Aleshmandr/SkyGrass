Shader "Grass/TessellatedGrassShadow"
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
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
                "IgnoreProjector" = "True"
            }

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "GeometryGrass.cginc"
            #include "Tessellation.cginc"
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geomTriangle
            #pragma multi_compile_fwdbase

            fixed3 _Color1;
            fixed3 _Color2;

            half4 frag(g2f i) : COLOR
            {
                fixed4 color = lerp(_Color1, _Color2, i.uv.y).xyzz;
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

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "GeometryGrass.cginc"
            #include "Tessellation.cginc"
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geomTriangle
            #pragma multi_compile_shadowcaster

            float4 frag(g2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
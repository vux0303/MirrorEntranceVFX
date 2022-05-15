Shader "MirrorEntrancePart2"
{
    Properties
    {
        _Ref("Ref", Integer) = 1
    }
    SubShader
    {
        Tags {
               "RenderType" = "Opaque"
               "Queue" = "Transparent"
             }

        Pass
        {
            Stencil {
                Ref 0
                ReadMask 1
                Comp NotEqual
                Pass Keep
			}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #include "MirrorDimensionLight.cginc"

            ENDCG
        }
    }
}

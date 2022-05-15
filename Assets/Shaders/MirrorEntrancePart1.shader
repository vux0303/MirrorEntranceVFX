Shader "MirrorEntrance"
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
                Ref 1
                ReadMask 1
                Comp NotEqual
                Pass Keep
			}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "MirrorDimensionLight.cginc"

            ENDCG
        }
    }
}

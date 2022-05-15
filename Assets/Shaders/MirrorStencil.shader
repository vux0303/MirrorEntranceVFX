Shader "MirrorStencil"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Stencil {
                Ref 1
                WriteMask 1
                Comp NotEqual
                Pass Replace
			}

            ColorMask 0
            ZWrite Off
        }
    }
}

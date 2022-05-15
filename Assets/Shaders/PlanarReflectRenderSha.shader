Shader "PlanarReflectSha"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ReflectionTex ("ReflectionTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _ReflectionTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 textureCoordinate = i.screenPos.xy / i.screenPos.w;
                textureCoordinate.x = 1.0f - textureCoordinate.x;
                fixed4 reflectiveColor = tex2D(_ReflectionTex, textureCoordinate) * 0.5f;
                //float aspect = _ScreenParams.x / _ScreenParams.y;
                //textureCoordinate.x = textureCoordinate.x * aspect;
                //textureCoordinate = TRANSFORM_TEX(textureCoordinate, _MainTex);
                fixed4 col = tex2D(_MainTex, i.uv) * 0.5f + reflectiveColor;
                return col;
            }
            ENDCG
        }
    }
}

Shader "OverlayTest"
{
    Properties
    {
        //_MainTex("Texture", 2D) = "white" {}
        _HorizontalSize("HorizontalSize", float) = 10.0
        _VerticalSize("_VerticalSize", float) = 10.0
        _Thickness("Thickness", float) = 0.1
        _planeScal("PlaneScale", float) = 2
        expectedOverlaySize("expectedOverlaySize", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 
                "Queue" = "Transparent"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.1415926538

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 wPos : TEXCOORD1;
                float3 oPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 worldNormal : TEXCOORD4;
            };

            //sampler2D _MainTex;
            sampler2D _CameraOpaqueTexture;
            float _HorizontalSize;
            float _Thickness;
            float _VerticalSize;
            float _planeScal;
            float expectedOverlaySize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.oPos = v.vertex;
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float3 rotate(float3 src, float angle) {
                float3x3 mat = float3x3(cos(angle), -sin(angle), 0,
                                        sin(angle), cos(angle) , 0,
                                        0         , 0          , 1);
                return float3(mul(mat, src));
			}

            fixed4 frag (v2f i) : SV_Target
            {
                float dist = length(_WorldSpaceCameraPos - i.wPos) /5.f;
                float2 textureCoordinate = i.screenPos.xy / i.screenPos.w;

                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
                half3 refractDirR = refract(-worldViewDir, i.worldNormal, 0.5f - 0.2f);
                half3 refractDirG = refract(-worldViewDir, i.worldNormal, 0.5f);
                half3 refractDirB = refract(-worldViewDir, i.worldNormal, 0.5f + 0.2f);

                fixed4 refractiveColor = fixed4(0,0,0,1);
                refractiveColor.r = tex2D(_CameraOpaqueTexture, i.uv  + refractDirR / 5).r;
                refractiveColor.g = tex2D(_CameraOpaqueTexture, i.uv  + refractDirG / 5).g;
                refractiveColor.b = tex2D(_CameraOpaqueTexture, i.uv  + refractDirB / 5).b;


                float scrollSpeed = _Time.y;

                //float expectedOverlaySize = 1.f; //3.f
                float overlayRatio = 0.3f; //0.25f
                //float currentOverlaySize = 2 * PI * _planeScal * overlayRatio;
                //float gradientScale = currentOverlaySize / expectedOverlaySize;

                float stepResolution = 100;

                float shiftDistance = cos(PI * overlayRatio);

                float2 flashDirection = normalize(float2(0, 1));
                float flashDirectionGradient = i.oPos.x * flashDirection.x * _planeScal + i.oPos.z * flashDirection.y * _planeScal;

                //float gradientSpeed = scrollSpeed * 2.f / expectedOverlaySize;
                //float gradient = stepResolution * (sin(flashDirectionGradient * gradientScale + gradientSpeed + 300) + shiftDistance);
                float gradient = stepResolution * (sin(2*PI* overlayRatio / expectedOverlaySize * (flashDirectionGradient + scrollSpeed - 15))  + shiftDistance);

                float overLaySpeed = (scrollSpeed / (5.f * _planeScal) + 1) * 0.5f; //to match gradient animating speed
                //float2x2 rotates = float2x2(cos(PI/2), -sin(PI/2), sin(PI/2), cos(PI/2));
                //float2 newone = mul(rotates, flashDirection);
                float4 overLayColor = tex2D(_CameraOpaqueTexture, frac(i.uv - flashDirection * overLaySpeed));
                //float4 overLayColor = tex2D(_CameraOpaqueTexture, frac(textureCoordinate - newone * overLaySpeed));
                //float4 overLayColor = tex2D(_CameraOpaqueTexture, frac(textureCoordinate + float2(0.5f, 0.5f)));
                float4 outputColor; 
                if (gradient < 1) {
                    outputColor = overLayColor;
				} else {
                    outputColor = float4(0,0,0,0);
				}
                return float4(outputColor);

                return float4(overLayColor);

                i.uv = half2(i.uv.x * (_HorizontalSize + _Thickness), i.uv.y);
                fixed2 fractionedUVs = frac(i.uv);
                fixed2 steppedUVs = step(fractionedUVs, _Thickness);
                fixed4 grid = steppedUVs.x;
                return grid;
            }
            ENDCG
        }
    }
}
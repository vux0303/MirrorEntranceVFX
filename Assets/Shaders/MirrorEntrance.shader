Shader "MirrorEntrance"
{
    Properties
    {
        _Ref("Ref", Integer) = 1
        _Color("Color", Vector) = (0,0,0,0)
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
                Ref [_Ref]
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
            #include "RandomFunctions.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
				half3 normal : NORMAL;
                half4 color: COLOR;
			};

            struct v2f 
			{
                half4 clipPos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 worldPos : TEXCOORD1;
                half3 worldNormal : TEXCOORD2;
                nointerpolation half4 color: TEXCOORD3;
                half4 screenPos: TEXCOORD4;
                half4 oPos: TEXCOORD5; //object pos
            };

            sampler2D _CameraOpaqueTexture;
            sampler2D _ReflectionTex;
            float _planeScale;
            float4 _Color;
            int _Ref;

            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.color = v.color;
                o.screenPos = ComputeScreenPos(o.clipPos);
                o.oPos = v.vertex;
                o.uv = v.uv;
                return o;
            }

            #define PI 3.1415926538

            fixed4 frag (v2f i) : SV_Target
            {
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //
                // Reflective triangles
                //
                half2 textureCoordinate = i.screenPos.xy / i.screenPos.w;
                textureCoordinate.x = 1.0f - textureCoordinate.x;
                textureCoordinate += i.color.yy;
                textureCoordinate = frac(textureCoordinate);
                half4 reflectiveColor = tex2D(_ReflectionTex, textureCoordinate) * (i.color.x == 1);

                //
                // Refractive triangles
                //
                textureCoordinate = i.screenPos.xy / i.screenPos.w;
                textureCoordinate += i.color.zz;
                textureCoordinate = frac(textureCoordinate);
                half4 refractiveColor = tex2D(_CameraOpaqueTexture, textureCoordinate) * (i.color.x == 0);

                //
                // Calculating flashing overlay on top
                // With expectedOverlaySize and randOverlayRatio as input, we move the sin wave in random direction and map with _CameraOpaqueTexture scroll speed,
                // so the texture appear to be moving with each triangle.
                // https://www.desmos.com/calculator/dq54ty4zma
                //
                half ran1d = rand3dTo1d(i.color.yzw);
                half scrollSpeed = (ran1d * 20 + 5) * _Time.y; // random in range (5, 25) * _Time.y;
                half expectedOverlaySize = i.color.w * 3; //match sure the black gradient cover a triangle
                half randOverlayRatio = ran1d * 0.1 + 0.05; // random in range (0.05, 0.15);
                half shiftDistance = cos(PI * randOverlayRatio);
                half2 flashDirection = normalize((rand3dTo2d(i.color.yzw) - 0.5) * 2); //shift [0, 1] to [-1, 1]
                half flashDirectionGradient = (i.oPos.x * flashDirection.x + i.oPos.y * flashDirection.y);
                half randStart = ran1d * 300000;
                half gradient = 100 * (sin(2*PI*randOverlayRatio / expectedOverlaySize * (flashDirectionGradient + scrollSpeed - randStart)) + shiftDistance);

                //index of refraction for 6 color channels
                //https://www.taylorpetrick.com/blog/post/dispersion-opengl
                //https://www.shadertoy.com/view/wt2GDW
                half eta_r = 1.0 / 1.15;
                half eta_y = 1.0 / 1.17;
                half eta_g = 1.0 / 1.19;
                half eta_c = 1.0 / 1.21;
                half eta_b = 1.0 / 1.23;
                half eta_v = 1.0 / 1.25;

                half2 refract_r = refract(-worldViewDir, i.worldNormal, eta_r).xy * 2.5;
                half2 refract_y = refract(-worldViewDir, i.worldNormal, eta_y).xy * 2.5;
                half2 refract_g = refract(-worldViewDir, i.worldNormal, eta_g).xy * 2.5;
                half2 refract_c = refract(-worldViewDir, i.worldNormal, eta_c).xy * 2.5;
                half2 refract_b = refract(-worldViewDir, i.worldNormal, eta_b).xy * 2.5;
                half2 refract_v = refract(-worldViewDir, i.worldNormal, eta_v).xy * 2.5;

                half overLaySpeed = (scrollSpeed / _planeScale + 1) * 0.5; //to match gradient animating speed
                // + flashDirection * overLaySpeed
                half3 tex_r = tex2D(_CameraOpaqueTexture, frac(refract_r + i.uv + flashDirection * overLaySpeed)).rgb;
                half3 tex_y = tex2D(_CameraOpaqueTexture, frac(refract_y + i.uv + flashDirection * overLaySpeed)).rgb;
                half3 tex_g = tex2D(_CameraOpaqueTexture, frac(refract_g + i.uv + flashDirection * overLaySpeed)).rgb;
                half3 tex_c = tex2D(_CameraOpaqueTexture, frac(refract_c + i.uv + flashDirection * overLaySpeed)).rgb;
                half3 tex_b = tex2D(_CameraOpaqueTexture, frac(refract_b + i.uv + flashDirection * overLaySpeed)).rgb;
                half3 tex_v = tex2D(_CameraOpaqueTexture, frac(refract_v + i.uv + flashDirection * overLaySpeed)).rgb;

                half r = tex_r.r * 0.5;
                half g = tex_g.g * 0.5;
                half b = tex_b.b * 0.5;
                half y = dot(half3(2.0, 2.0, -1.0), tex_y)/6.0;
                half c = dot(half3(-1.0, 2.0, 2.0), tex_c)/6.0;
                half v = dot(half3(2.0, -1.0, 2.0), tex_v)/6.0;

                half R = r + (2.0 * v + 2.0 * y - c)/3.0;
                half G = g + (2.0 * y + 2.0 * c - v)/3.0;
                half B = b + (2.0 * c + 2.0 * v - y)/3.0;

                half4 overLayColor = half4(R + 0.15, G + 0.15, B + 0.05, 1);

                //
                // Combine result
                //
                half4 outputColor = refractiveColor + reflectiveColor;
                if (gradient < 1) outputColor = overLayColor;
                return outputColor;
            }

            ENDCG
        }
    }
}

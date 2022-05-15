            #include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float4 color: COLOR;
			};

            struct v2f 
			{
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 pos : SV_POSITION;
                nointerpolation float4 color: TEXCOORD2;
                float4 screenPos: TEXCOORD3;
            };

            sampler2D _CameraOpaqueTexture;
            sampler2D _ReflectionTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.color = v.color;
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }
        
             float3 custom( float3 i, float3 n, float eta )
            {
                float cosi = dot(-i, n);
                float cost2 = 1 - eta * eta * (1.0f - cosi*cosi);
                float3 t = eta*i + ((eta*cosi - sqrt(abs(cost2))) * n);
                return t * (float3)(cost2 > 0);
            }

            float3 varyReflect( float3 i, float3 n, float v)
            {
                return i - 2.0 * n * dot(n,i) * 1;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 textureCoordinate = i.screenPos.xy / i.screenPos.w;
                textureCoordinate.x = 1.0f - textureCoordinate.x;
                textureCoordinate += i.color.yy;
                textureCoordinate = frac(textureCoordinate);
                fixed4 reflectiveColor = tex2D(_ReflectionTex, textureCoordinate) * (i.color.x == 1);

                textureCoordinate = i.screenPos.xy / i.screenPos.w;
                textureCoordinate += i.color.zz;
                textureCoordinate = frac(textureCoordinate);
                fixed4 refractiveColor = tex2D(_CameraOpaqueTexture, textureCoordinate) * (i.color.x == 0);

                fixed4 outputColor = refractiveColor + reflectiveColor;

                return float4(outputColor.xyz, 1);

                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //Direction of ray from the camera towards the object surface
                half3 reflection = varyReflect(-worldViewDir, i.worldNormal, i.color.x); // Direction of ray after hitting the surface of object
                //half3 combine = reflection + reflect(-worldViewDir, i.worldNormal) * (reflection == 0); 
				/*If Roughness feature is not needed : UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection) can be used instead.
				It chooses the correct LOD value based on camera distance*/
                half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, -worldViewDir, 0);
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR); // This is done becasue the cubemap is stored HDR
                return half4(skyColor, 1.0);
            }
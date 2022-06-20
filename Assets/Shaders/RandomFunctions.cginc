            //https://www.ronja-tutorials.com/post/024-white-noise/
            
            half rand2dTo1d(half2 value, half2 dotDir = half2(12.9898, 78.233))
            {
                half2 smallValue = sin(value);
                half random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            half2 rand2dTo2d(half2 value)
            {
                return half2(
                    rand2dTo1d(value, half2(12.989, 78.233)),
                    rand2dTo1d(value, half2(39.346, 11.135))
                );
            }

            half rand3dTo1d(half3 value, half3 dotDir = half3(12.9898, 78.233, 37.719))
            {
                //make value smaller to avoid artefacts
                half3 smallValue = sin(value);
                //get scalar value from 3d vector
                half random = dot(smallValue, dotDir);
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            half2 rand3dTo2d(half3 value)
            {
                return half2(
                    rand3dTo1d(value, half3(12.989, 78.233, 37.719)),
                    rand3dTo1d(value, half3(39.346, 11.135, 83.155))
                );
            }
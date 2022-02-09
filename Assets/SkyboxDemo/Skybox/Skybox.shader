Shader "Unlit/Skybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTextureIntensity("Texture intensity", Range(0,1)) = 1
        _MainTextureAdd("Texture add", Range(0,1)) = 0
        _Color("Color", Color) = (1,1,1,1)
        _SpeedParameters("Speed parameters", Vector) = (1,1,1,1)
        _ParallaxStrength("Parallax Strength", Range(0, 1)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+100"}
        LOD 100
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                half4 tangent : TANGENT;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                half3 tangentViewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            half _MainTextureAdd;
            half _MainTextureIntensity;
            half4 _SpeedParameters;
            half _ParallaxStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 bitangent = cross(v.normal, v.tangent.xyz) * tangentSign;

                float3x3 objectToTangent = float3x3(v.tangent.xyz, bitangent.xyz, v.normal.xyz);

                float3 objSpaceViewDir = ObjSpaceViewDir(float4(v.vertex.xyz, 1));
                o.tangentViewDir = mul(objectToTangent, objSpaceViewDir);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float2 uv = i.uv + _SpeedParameters.xy * _Time;
                float2 uv2 = i.uv + _SpeedParameters.zw * _Time;

                half height = tex2D(_MainTex, uv).x;
                height += tex2D(_MainTex, uv2).x;
                height *= 0.5;

                i.tangentViewDir = normalize(i.tangentViewDir);
                i.tangentViewDir.xy /= (i.tangentViewDir.z + 0.42);
                half modHeight = height - 0.5;
                float2 parallax = i.tangentViewDir.xy * _ParallaxStrength * modHeight;
                uv = uv + parallax;

                fixed4 col1 = tex2D(_MainTex, uv);
                fixed4 col2 = tex2D(_MainTex, uv2);

                fixed4 col = lerp(col1, col2, 0.5);
                col += _MainTextureAdd;
                col *= _Color;

                col = lerp(_Color, col, _MainTextureIntensity);

                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
